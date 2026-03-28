import 'package:flutter/material.dart';

class Skeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const Skeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  const Skeleton.circle({super.key, required double size})
      : width = size,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.shape,
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-0.4 + 2.0 * _controller.value, 0),
              colors: [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class SkeletonImage extends StatelessWidget {
  final ImageProvider image;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const SkeletonImage({
    super.key,
    required this.image,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: Image(
          image: image,
          width: width,
          height: height,
          fit: fit,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }
            return Skeleton(width: width, height: height, borderRadius: 0);
          },
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            color: Color(0xFFE0E0E0),
            child: Icon(Icons.broken_image, size: 18, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
