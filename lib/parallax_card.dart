import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ParallaxCard extends StatefulWidget {
  const ParallaxCard({
    super.key,
    required this.width,
    required this.height,
    required this.backgroundAsset,
    this.foregroundAsset,
    this.maxTiltDeg = 10,
    this.enableSparkleEffect = false,
  });

  final double width;
  final double height;
  final String backgroundAsset;
  final String? foregroundAsset;
  final double maxTiltDeg;
  final bool enableSparkleEffect;

  @override
  State<ParallaxCard> createState() => _ParallaxCardState();
}

class _ParallaxCardState extends State<ParallaxCard> {
  Offset _drag = Offset.zero;
  bool _isDragging = false;

  static const _cap = 80.0;
  double get _degToRad => math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final dx = (_drag.dx.clamp(-_cap, _cap)) / _cap;
    final dy = (_drag.dy.clamp(-_cap, _cap)) / _cap;

    final tiltX = -dy * (_isDragging ? widget.maxTiltDeg : 0) * _degToRad;
    final tiltY = dx * (_isDragging ? widget.maxTiltDeg : 0) * _degToRad;

    return GestureDetector(
      onPanStart: (_) => setState(() => _isDragging = true),
      onPanUpdate: (details) => setState(() => _drag += details.delta),
      onPanEnd: (_) {
        setState(() => _isDragging = false);
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
          final shineOffset = Offset(-value.dx / 1.5, -value.dy / 1.5);

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
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
                    Image.asset(widget.backgroundAsset, fit: BoxFit.cover),
                    if (widget.foregroundAsset != null)
                      Image.asset(widget.foregroundAsset!, fit: BoxFit.contain),

                    widget.enableSparkleEffect
                        ? Positioned(
                            left: (widget.width - 300) / 2 + shineOffset.dx,
                            top: (widget.height - 300) / 2 + shineOffset.dy,
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 50,
                                sigmaY: 50,
                              ),
                              child: SizedBox(
                                width: 300,
                                height: 300,
                                //   color: Colors.white.withAlpha(170),
                                // ),
                                child: Opacity(
                                  opacity: 0.2,
                                  child: RainbowHolographicOverlay(
                                    enable: true,
                                    locationRatioX:
                                        0.1, // di chuyển dải hologram
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Positioned(
                            left: (widget.width - 300) / 2 + shineOffset.dx,
                            top: (widget.height - 50) / 2 + shineOffset.dy,
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 50,
                                sigmaY: 50,
                              ),
                              child: Container(
                                width: 300,
                                height: 50,
                                color: Colors.white.withAlpha(170),
                              ),
                            ),
                          ),

                    // tôi muốn thay hiệu ứng di chuyển cho rainbow giống như cái ImageFiltered
                    // RainbowHolographicOverlay(
                    //   enable: true,
                    //   locationRatioX: 0.45, // di chuyển dải hologram
                    // ),
                    SparkleBlendOverlay(
                      enable: widget.enableSparkleEffect,
                      opacity: 0.1,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _drag = Offset.zero);
    });
  }
}

class SparkleBlendOverlay extends StatefulWidget {
  const SparkleBlendOverlay({
    super.key,
    required this.enable,
    this.opacity = 0.3,
    this.holoAsset = 'assets/holo.png',
    this.sparkleGifAsset = 'assets/sparkles.gif',
  });

  final bool enable;
  final double opacity; // 0..1
  final String holoAsset;
  final String sparkleGifAsset;

  @override
  State<SparkleBlendOverlay> createState() => _SparkleBlendOverlayState();
}

class _SparkleBlendOverlayState extends State<SparkleBlendOverlay> {
  ui.Image? _holo;
  ui.Codec? _gifCodec;
  ui.FrameInfo? _frame;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SparkleBlendOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.holoAsset != widget.holoAsset ||
        oldWidget.sparkleGifAsset != widget.sparkleGifAsset) {
      _disposeGif();
      _load();
    }
  }

  Future<void> _load() async {
    // Load holo (PNG)
    final holoBytes = await rootBundle.load(widget.holoAsset);
    final holoCodec = await ui.instantiateImageCodec(
      holoBytes.buffer.asUint8List(),
    );
    _holo = (await holoCodec.getNextFrame()).image;

    // Load GIF codec
    final gifBytes = await rootBundle.load(widget.sparkleGifAsset);
    _gifCodec = await ui.instantiateImageCodec(gifBytes.buffer.asUint8List());

    _scheduleNextFrame();
    if (mounted) setState(() {});
  }

  void _scheduleNextFrame() async {
    if (_gifCodec == null) return;
    _frame = await _gifCodec!.getNextFrame();
    if (!mounted) return;
    setState(() {});
    _timer?.cancel();
    _timer = Timer(_frame!.duration, _scheduleNextFrame);
  }

  void _disposeGif() {
    _timer?.cancel();
    _timer = null;
    _gifCodec = null;
    _frame = null;
  }

  @override
  void dispose() {
    _disposeGif();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enable) return const SizedBox.shrink();
    return Opacity(
      opacity: 0.2,
      child: CustomPaint(
        painter: _SparklePainter(
          holo: _holo,
          sparkle: _frame?.image,
          opacity: widget.opacity,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({this.holo, this.sparkle, required this.opacity});

  final ui.Image? holo;
  final ui.Image? sparkle;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (holo == null && sparkle == null) return;
    final dst = Offset.zero & size;

    // Vẽ trên layer để áp dụng blend với nền đã có
    canvas.saveLayer(dst, Paint());

    final dodgePaint = Paint()
      ..blendMode = BlendMode.colorDodge
      // giảm cường độ tương đương .opacity(0.3) ở SwiftUI
      ..colorFilter = ui.ColorFilter.mode(
        Colors.white.withAlpha((opacity * 255).round()),
        BlendMode.srcATop,
      );

    if (holo != null) {
      final srcH = Rect.fromLTWH(
        0,
        0,
        holo!.width.toDouble(),
        holo!.height.toDouble(),
      );
      canvas.drawImageRect(holo!, srcH, dst, dodgePaint);
    }

    if (sparkle != null) {
      final srcS = Rect.fromLTWH(
        0,
        0,
        sparkle!.width.toDouble(),
        sparkle!.height.toDouble(),
      );
      canvas.drawImageRect(sparkle!, srcS, dst, dodgePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.holo != holo ||
      oldDelegate.sparkle != sparkle ||
      oldDelegate.opacity != opacity;
}

class RainbowHolographicOverlay extends StatelessWidget {
  const RainbowHolographicOverlay({
    super.key,
    required this.enable,
    required this.locationRatioX, // 0..1
  });

  final bool enable;
  final double locationRatioX;

  // @override
  // Widget build(BuildContext context) {
  //   if (!enable) return const SizedBox.shrink();
  //   return Positioned.fill(
  //     child: CustomPaint(
  //       painter: _RainbowPainter(
  //         centerRatioX: locationRatioX,
  //         rotationDeg: 20,
  //         padding: 60,
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    if (!enable) return const SizedBox.shrink();
    return SizedBox.expand(
      // thay cho Positioned.fill
      child: CustomPaint(
        painter: _RainbowPainter(
          centerRatioX: locationRatioX,
          rotationDeg: 20,
          padding: 60,
        ),
      ),
    );
  }
}

class _RainbowPainter extends CustomPainter {
  _RainbowPainter({
    required this.centerRatioX,
    required this.rotationDeg,
    required this.padding,
  });

  final double centerRatioX;
  final double rotationDeg;
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    // clamp 0.21..0.79
    final c = centerRatioX.clamp(0.21, 0.79);

    // toạ độ vẽ mở rộng như padding(-60)
    final rect = Rect.fromLTWH(
      -padding,
      -padding,
      size.width + 2 * padding,
      size.height + 2 * padding,
    );

    // gradient ngang (leading → trailing)
    final colors = <Color>[
      Colors.transparent,
      _hex('#ec9bb6'),
      _hex('#ccac6f'),
      _hex('#69e4a5'),
      _hex('#8ec5d6'),
      _hex('#b98cce'),
      Colors.transparent,
    ];
    final stops = <double>[
      0.0,
      (c - 0.2).clamp(0.0, 1.0),
      (c - 0.1).clamp(0.0, 1.0),
      c.clamp(0.0, 1.0),
      (c + 0.1).clamp(0.0, 1.0),
      (c + 0.2).clamp(0.0, 1.0),
      1.0,
    ];

    final shader = ui.Gradient.linear(
      rect.topLeft,
      rect.topRight,
      colors,
      stops,
    );

    // blend overlay như SwiftUI .blendMode(.overlay)
    final paint = Paint()
      ..blendMode = BlendMode.overlay
      ..shader = shader;

    // xoay 20°
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotationDeg * math.pi / 180.0);
    canvas.translate(-size.width / 2, -size.height / 2);

    // vẽ lên layer để bảo toàn blending với nền đã có
    final dst = Offset.zero & size;
    canvas.saveLayer(dst, Paint()); // layer nền
    canvas.drawRect(rect, paint); // phủ gradient overlay
    canvas.restore(); // áp blend
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RainbowPainter old) =>
      old.centerRatioX != centerRatioX ||
      old.rotationDeg != rotationDeg ||
      old.padding != padding;

  static Color _hex(String s) {
    final v = int.parse(s.replaceAll('#', ''), radix: 16);
    return Color(0xFF000000 | v); // alpha 255
  }
}
