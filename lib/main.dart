import 'package:flutter/material.dart';
import 'package:pokemoncard/parallax_card.dart';

void main() => runApp(const ParallaxDemoApp());

class ParallaxDemoApp extends StatefulWidget {
  const ParallaxDemoApp({super.key});

  @override
  State<ParallaxDemoApp> createState() => _ParallaxDemoAppState();
}

class _ParallaxDemoAppState extends State<ParallaxDemoApp> {
  bool _enableSparkle = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        bottomNavigationBar: SafeArea(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
            ),
            onPressed: () => setState(() {
              _enableSparkle = !_enableSparkle;
            }),
            child: Text(_enableSparkle ? 'Tắt Hiệu Ứng' : 'Bật Hiệu Ứng'),
          ),
        ),
        body: Center(
          child: ParallaxCard(
            width: 316,
            height: 417,
            backgroundAsset: 'assets/queen.png',
            foregroundAsset: null,
            enableSparkleEffect: _enableSparkle, // bật hiệu ứng phủ
          ),
        ),
      ),
    );
  }
}
