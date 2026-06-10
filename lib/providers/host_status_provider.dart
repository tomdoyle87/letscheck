import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HostState { ok, warning, critical, unknown }

final hostStatusProvider =
    StateProvider<HostState>((ref) => HostState.unknown);
