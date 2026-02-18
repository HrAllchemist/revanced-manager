import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class MegamanX3Demo extends StatefulWidget {
  const MegamanX3Demo({Key? key}) : super(key: key);

  @override
  State<MegamanX3Demo> createState() => _MegamanX3DemoState();
}

class _MegamanX3DemoState extends State<MegamanX3Demo> {
  static const double _groundY = 128;
  static const double _playerHeight = 48;
  static const double _gravity = 0.85;
  static const double _jumpVelocity = -14;

  Timer? _timer;
  double _playerX = 24;
  double _playerY = _groundY - _playerHeight;
  double _velocityY = 0;
  bool _movingLeft = false;
  bool _movingRight = false;
  bool _shooting = false;

  final List<_Projectile> _shots = [];
  final _Enemy _enemy = _Enemy(x: 250, y: _groundY - 44, width: 34, height: 44);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _update());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _update() {
    if (!mounted) return;

    setState(() {
      if (_movingLeft) _playerX -= 3;
      if (_movingRight) _playerX += 3;
      _playerX = _playerX.clamp(0, 290);

      _velocityY += _gravity;
      _playerY += _velocityY;

      final floorY = _groundY - _playerHeight;
      if (_playerY >= floorY) {
        _playerY = floorY;
        _velocityY = 0;
      }

      for (final shot in _shots) {
        shot.x += 8;
      }
      _shots.removeWhere((shot) => shot.x > 340);

      final enemyBox = Rect.fromLTWH(_enemy.x, _enemy.y, _enemy.width, _enemy.height);
      for (final shot in _shots) {
        final shotBox = Rect.fromCircle(center: Offset(shot.x, shot.y), radius: shot.radius);
        if (enemyBox.overlaps(shotBox)) {
          _enemy.hitFlashFrames = 8;
          shot.x = 400;
        }
      }

      if (_enemy.hitFlashFrames > 0) {
        _enemy.hitFlashFrames--;
      }
    });
  }

  void _jump() {
    if (_playerY >= _groundY - _playerHeight) {
      setState(() => _velocityY = _jumpVelocity);
    }
  }

  void _shoot() {
    if (_shooting) return;
    setState(() {
      _shooting = true;
      _shots.add(_Projectile(x: _playerX + 30, y: _playerY + 24));
    });
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() => _shooting = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 20, bottom: 30),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MegaMan X3-style mini demo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Left/Right برای حرکت، Jump برای پرش، Shoot برای تیر.',
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 180,
                child: CustomPaint(
                  painter: _MegamanPainter(
                    playerX: _playerX,
                    playerY: _playerY,
                    groundY: _groundY,
                    shots: _shots,
                    shooting: _shooting,
                    enemy: _enemy,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _holdButton(
                  label: '◀ Left',
                  onHoldChanged: (value) => setState(() => _movingLeft = value),
                ),
                _holdButton(
                  label: 'Right ▶',
                  onHoldChanged: (value) => setState(() => _movingRight = value),
                ),
                FilledButton(onPressed: _jump, child: const Text('Jump')),
                FilledButton.tonal(onPressed: _shoot, child: const Text('Shoot')),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _holdButton({
    required String label,
    required ValueChanged<bool> onHoldChanged,
  }) {
    return GestureDetector(
      onTapDown: (_) => onHoldChanged(true),
      onTapUp: (_) => onHoldChanged(false),
      onTapCancel: () => onHoldChanged(false),
      child: FilledButton.tonal(
        onPressed: () {},
        child: Text(label),
      ),
    );
  }
}

class _MegamanPainter extends CustomPainter {
  _MegamanPainter({
    required this.playerX,
    required this.playerY,
    required this.groundY,
    required this.shots,
    required this.shooting,
    required this.enemy,
  });

  final double playerX;
  final double playerY;
  final double groundY;
  final List<_Projectile> shots;
  final bool shooting;
  final _Enemy enemy;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()..color = const Color(0xFF10162F);
    final floor = Paint()..color = const Color(0xFF263238);
    final player = Paint()..color = const Color(0xFF4FC3F7);
    final playerHelmet = Paint()..color = const Color(0xFF81D4FA);
    final shotPaint = Paint()..color = const Color(0xFF64FFDA);
    final enemyPaint = Paint()
      ..color = enemy.hitFlashFrames > 0 ? const Color(0xFFFF8A80) : const Color(0xFFEF5350);

    canvas.drawRect(Offset.zero & size, sky);
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, size.height - groundY), floor);

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawRect(
        Rect.fromLTWH(x, groundY + 14 + 2 * math.sin(x / 25), 10, 4),
        Paint()..color = Colors.white12,
      );
    }

    final playerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(playerX, playerY + 10, 24, 38),
      const Radius.circular(6),
    );
    canvas.drawRRect(playerRect, player);
    canvas.drawCircle(Offset(playerX + 12, playerY + 10), 10, playerHelmet);

    if (shooting) {
      canvas.drawCircle(Offset(playerX + 28, playerY + 24), 4, shotPaint);
    }

    for (final shot in shots) {
      canvas.drawCircle(Offset(shot.x, shot.y), shot.radius, shotPaint);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(enemy.x, enemy.y, enemy.width, enemy.height),
        const Radius.circular(5),
      ),
      enemyPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MegamanPainter oldDelegate) => true;
}

class _Projectile {
  _Projectile({required this.x, required this.y, this.radius = 3.5});

  double x;
  final double y;
  final double radius;
}

class _Enemy {
  _Enemy({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.hitFlashFrames = 0,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  int hitFlashFrames;
}
