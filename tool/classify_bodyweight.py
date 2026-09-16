#!/usr/bin/env python3
"""Curate the `bodyweight` flag on every exercise in the dataset.

The raw free-exercise-db `equipment` tag is unreliable for telling whether a
movement is loaded by the lifter's own bodyweight (dips and muscle-ups are
tagged `other`, calf raises `machine`, etc.), so we classify by movement name +
category and write an explicit `bodyweight: true|false` onto each entry. The app
(`CatalogExercise.usesBodyweight`) prefers that flag over the equipment guess.

Usage:
    python tool/classify_bodyweight.py            # review: print the decisions
    python tool/classify_bodyweight.py --apply    # write flags into the dataset
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATASET = os.path.join(ROOT, 'assets', 'data', 'exercises.json')

# Strong positive movement patterns (regex on the lowercased name).
POS = [
    r'pull[- ]?up', r'chin[- ]?up', r'grip chin', r'muscle[- ]?up',
    r'\bdip\b', r'\bdips\b',
    r'push[- ]?up', r'press[- ]?up', r'hand ?stand', r'wall walk', r'wall climb',
    r'\bplank\b', r'mountain climber', r'\bburpee', r'\bcrunch', r'sit[- ]?up',
    r'leg raise', r'knee raise', r'leg lift', r'knee tuck', r'toes[- ]to[- ]bar',
    r'\bhanging\b', r'l[- ]?sit', r'\bhollow\b', r'\bv[- ]?up', r'flutter kick',
    r'\bsuperman\b', r'bird ?dog', r'dead ?bug', r'russian twist',
    r'hyperextension', r'back extension', r'reverse hyper',
    r'air squat', r'body ?weight squat', r'prisoner squat', r'\bpistol\b',
    r'sissy squat', r'shrimp squat', r'jump squat', r'squat jump', r'box jump',
    r'broad jump', r'tuck jump', r'jumping jack', r'high knee', r'star jump',
    r'body ?weight lunge', r'\binverted row', r'body ?weight row', r'\bring row',
    r'suspended', r'australian pull', r'\bfrog\b', r'skin the cat', r'front lever',
    r'back lever', r'human flag', r'\bplanche\b', r'\bbridge\b', r'hip raise',
    r'glute bridge', r'\bl[- ]?pull', r'bench dip', r'tricep dip', r'triceps dip',
    r'parallel bar', r'korean dip',
    r'negative', r'windshield wiper', r'\bv sit', r'knees to elbow',
    r'\bcossack', r'\bwall sit',
]
POS_RE = [re.compile(p) for p in POS]

# Names that force NOT-bodyweight even if a positive pattern matched (weighted
# moves whose names collide with calisthenics keywords).
HARD_NEG = ['good morning', 'jerk', 'seated calf', 'rope crunch',
            'cable crunch', 'press to chin']

# A named machine/implement / assistance means the external device bears the
# load, so a name match should not count as bodyweight.
NEG_TOKENS = [
    'assisted', 'machine', 'smith', 'hammer strength', 'lever ', 'cable',
    'band ', 'bands', 'sled', 'leg press', 'pulldown', 'pull-down', 'pull down',
]

# Ambiguous patterns that flip to weighted when the name carries an implement.
IMPLEMENT_TOKENS = ['barbell', 'dumbbell', 'kettlebell', 'ez bar', 'e-z',
                    'ez-bar', 'plate', 'landmine', 'trap bar', 'medicine ball',
                    'band']
AMBIG = ['step', 'bridge', 'glute bridge', 'hip raise', 'hip thrust',
         'russian twist', 'windshield']


def classify(e):
    """Return (is_bodyweight, reason)."""
    name = e['name'].lower()
    cat = (e.get('category') or '').lower()
    eq = (e.get('equipment') or '').lower()

    if cat == 'stretching' or 'stretch' in name:
        return False, 'stretch'
    if cat == 'cardio' and eq != 'body only':
        return False, 'cardio'
    if any(t in name for t in HARD_NEG):
        return False, 'hard-neg'

    matched = any(r.search(name) for r in POS_RE)
    has_neg = any(t in name for t in NEG_TOKENS)
    has_implement = any(t in name for t in IMPLEMENT_TOKENS)

    if matched and not has_neg:
        if has_implement and any(a in name for a in AMBIG):
            return False, 'implement-variant'
        return True, 'name'

    if eq == 'body only':
        return True, 'body-only'

    return False, 'default'


def main():
    apply = '--apply' in sys.argv[1:]
    data = json.load(open(DATASET, encoding='utf-8'))

    out, true_ct = [], 0
    for e in data:
        bw, _ = classify(e)
        true_ct += bw
        # Insert `bodyweight` right after `equipment` for a clean diff.
        ne = {}
        for k, v in e.items():
            if k == 'bodyweight':
                continue
            ne[k] = v
            if k == 'equipment':
                ne['bodyweight'] = bw
        ne.setdefault('bodyweight', bw)
        out.append(ne)

    print(f'{len(data)} exercises -> bodyweight=True for {true_ct}')

    if apply:
        text = json.dumps(out, indent=2, ensure_ascii=False) + '\n'
        with open(DATASET, 'w', encoding='utf-8', newline='\n') as f:
            f.write(text)
        print(f'wrote {DATASET}')
    else:
        print('(review only — pass --apply to write flags into the dataset)')


if __name__ == '__main__':
    main()
