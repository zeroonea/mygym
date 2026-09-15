import 'dart:async';

import 'package:flutter/material.dart';

/// Plays an exercise's start/finish frames as a looping demo by cross-fading
/// between them. Falls back to a single static frame if only one is supplied.
class ExerciseDemo extends StatefulWidget {
  const ExerciseDemo({
    super.key,
    required this.frames,
    this.height = 220,
    this.borderRadius = 18,
  });

  final List<String> frames;
  final double height;
  final double borderRadius;

  @override
  State<ExerciseDemo> createState() => _ExerciseDemoState();
}

class _ExerciseDemoState extends State<ExerciseDemo> {
  Timer? _timer;
  bool _showFirst = true;

  @override
  void initState() {
    super.initState();
    if (widget.frames.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 950), (_) {
        if (mounted) setState(() => _showFirst = !_showFirst);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final f in widget.frames) {
      precacheImage(AssetImage(f), context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    final single = widget.frames.length < 2;
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.white,
        child: single
            ? Image.asset(widget.frames.first, fit: BoxFit.contain)
            : AnimatedCrossFade(
                duration: const Duration(milliseconds: 450),
                firstChild: Image.asset(widget.frames[0],
                    fit: BoxFit.contain, width: double.infinity),
                secondChild: Image.asset(widget.frames[1],
                    fit: BoxFit.contain, width: double.infinity),
                crossFadeState: _showFirst
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
              ),
      ),
    );
  }
}

/// A small static thumbnail (first frame) for list tiles.
class ExerciseThumb extends StatelessWidget {
  const ExerciseThumb({super.key, required this.frame, this.size = 46});

  final String frame;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        child: Image.asset(frame, fit: BoxFit.cover),
      ),
    );
  }
}
