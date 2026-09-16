import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Plays an exercise's start/finish frames as a looping demo by cross-fading
/// between them. Images stream from the network and are cached on device.
class ExerciseDemo extends StatefulWidget {
  const ExerciseDemo({
    super.key,
    required this.frames,
    this.height = 240,
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _frame(String url) => CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        width: double.infinity,
        placeholder: (_, _) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (_, _, _) => const Center(
            child: Icon(Icons.image_not_supported_outlined, size: 40)),
      );

  @override
  Widget build(BuildContext context) {
    final single = widget.frames.length < 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.white,
        child: single
            ? _frame(widget.frames.first)
            : AnimatedCrossFade(
                duration: const Duration(milliseconds: 450),
                firstChild: _frame(widget.frames[0]),
                secondChild: _frame(widget.frames[1]),
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
        child: CachedNetworkImage(
          imageUrl: frame,
          fit: BoxFit.cover,
          placeholder: (_, _) => const SizedBox.shrink(),
          errorWidget: (_, _, _) =>
              const Icon(Icons.fitness_center, size: 20),
        ),
      ),
    );
  }
}
