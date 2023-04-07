/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:math';

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/material.dart';

class AverageGradeCircle extends StatefulWidget {
  const AverageGradeCircle({Key? key, required this.average, required this.percent})
      : super(key: key);

  final double average;
  final double percent;

  @override
  State<AverageGradeCircle> createState() => _AverageGradeCircleState();
}

class _AverageGradeCircleState extends State<AverageGradeCircle> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1, milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.forward();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        var animation = Curves.decelerate.transform(_controller.value);

        return CustomPaint(
          painter: AverageCirclePainter(
            context: context,
            percent: widget.percent * animation,
          ),
          child: Center(
            child: Text((widget.average * animation).roundToPlaces(1).toString()).textScale(3),
          ),
        );
      },
    );
  }
}

class AverageCirclePainter extends CustomPainter {
  final double percent;
  final BuildContext context;

  AverageCirclePainter({
    required this.context,
    required this.percent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var percent = this.percent;
    var length = min(size.width, size.height);
    var offsetX = size.width - length;
    var offsetY = size.height - length;
    var rect = Rect.fromLTRB(
      20 + offsetX / 2,
      20 + offsetY / 2,
      length - 20 + offsetX / 2,
      length - 20 + offsetY / 2,
    );
    var paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = length * 0.04;

    var start = (3 * pi) / 2;
    var end = percent * (2 * pi);

    var col1 = Colors.red;
    var col2 = Colors.yellow;
    percent *= 2;
    if (percent > 1) {
      col1 = col2;
      col2 = Colors.green;
      percent -= 1;
    }

    if (percent == 0) {
      bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
      paint.color = isDarkMode ? Colors.grey[800]! : Colors.grey[400]!;

      canvas.drawArc(rect, start, 2 * pi, false, paint);
    }

    paint.color = Color.lerp(col1, col2, percent * 1.25)!;
    canvas.drawArc(rect, start, end, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
