import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

void main() => runApp(const ParallaxDemoApp());

class ParallaxDemoApp extends StatelessWidget {
  const ParallaxDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: ParallaxCard(
            width: 316,
            height: 417,
            backgroundAsset: 'assets/cardbg.png',
            // Có thể thêm một lớp nhân vật riêng nếu muốn:
            // foregroundAsset: 'assets/charizard.png',
          ),
        ),
      ),
    );
  }
}

class ParallaxCard extends StatefulWidget {
  const ParallaxCard({
    super.key,
    required this.width,
    required this.height,
    required this.backgroundAsset,
    this.maxTiltDeg = 10,
  });

  final double width;
  final double height;
  final String backgroundAsset;
  final double maxTiltDeg;

  @override
  State<ParallaxCard> createState() => _ParallaxCardState();
}

class _ParallaxCardState extends State<ParallaxCard> {
  Offset _drag = Offset.zero;
  bool _isDragging = false;

  // Giới hạn biên để tính tilt mượt.
  static const _cap = 80.0;

  double get _degToRad => math.pi / 180;

  @override
  Widget build(BuildContext context) {
    // Chuẩn hoá dx, dy trong [-1, 1] rồi nhân góc tối đa.
    final dx = (_drag.dx.clamp(-_cap, _cap)) / _cap;
    final dy = (_drag.dy.clamp(-_cap, _cap)) / _cap;

    final tiltX =
        -dy *
        (_isDragging ? widget.maxTiltDeg : 0) *
        _degToRad; // xoay quanh trục X theo kéo dọc
    final tiltY =
        dx *
        (_isDragging ? widget.maxTiltDeg : 0) *
        _degToRad; // xoay quanh trục Y theo kéo ngang

    return GestureDetector(
      onPanStart: (_) => setState(() => _isDragging = true),
      onPanUpdate: (details) => setState(() => _drag += details.delta),
      onPanEnd: (_) {
        setState(() {
          _isDragging = false;
        });
        // Animate về 0
        _animateBack();
      },
      onPanCancel: () {
        setState(() => _isDragging = false);
        _animateBack();
      },
      child: TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(begin: Offset.zero, end: _drag),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          // Dùng value cho offset shine để mượt.
          final shineOffset = Offset(-value.dx / 1.5, -value.dy / 1.5);

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(tiltX)
              ..rotateY(tiltY),
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Nền thẻ
                    Image.asset(widget.backgroundAsset, fit: BoxFit.cover),
                    // Tuỳ chọn: ảnh nhân vật phía trên nền

                    // Lớp "shine" tương tự Rectangle + colorInvert + blur + offset
                    // Flutter không có colorInvert đơn giản cho Container,
                    // nhưng một dải trắng mờ + blur cho hiệu ứng tương đương.
                    Positioned(
                      left: (widget.width - 300) / 2 + shineOffset.dx,
                      top: (widget.height - 50) / 2 + shineOffset.dy,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                        child: Container(
                          width: 300,
                          height: 50,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _animateBack() {
    // Trả drag về 0 bằng một khung hình tiếp theo để TweenAnimationBuilder animate.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _drag = Offset.zero);
    });
  }
}
