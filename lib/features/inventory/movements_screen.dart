import 'package:flutter/material.dart';

/// Global movements tab (bottom-nav branch). Placeholder for the MVP; the
/// per-product trail lives in [HistoryScreen].
class MovementsScreen extends StatelessWidget {
  const MovementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: const Center(child: Text('Historial de movimientos')),
    );
  }
}
