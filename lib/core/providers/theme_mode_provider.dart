import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Light-first. In-memory per session (persistence via shared_preferences is
/// a later slice).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
