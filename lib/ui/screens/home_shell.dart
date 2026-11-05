import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../core/theme.dart';
import '../keys.dart';
import 'board_screen.dart';
import 'mine_screen.dart';
import 'profile_screen.dart';
import 'staff_queue_screen.dart';

/// Student tabs: BOARD, MINE, ME. Staff tabs: QUEUE, BOARD, ME.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentUserProvider).value?.isStaff ?? false;
    final tabs = staff
        ? [
            (K.tabQueue, 'QUEUE', const StaffQueueScreen()),
            (K.tabBoard, 'BOARD', const BoardScreen()),
            (K.tabMe, 'ME', const ProfileScreen()),
          ]
        : [
            (K.tabBoard, 'BOARD', const BoardScreen()),
            (K.tabMine, 'MINE', const MineScreen()),
            (K.tabMe, 'ME', const ProfileScreen()),
          ];
    return Scaffold(
      body: tabs[_index].$3,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Snag.paper,
          border: Border(top: Snag.border),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (var n = 0; n < tabs.length; n++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: n == _index,
                    label: tabs[n].$2,
                    excludeSemantics: true,
                    child: InkWell(
                      key: tabs[n].$1,
                      onTap: () => setState(() => _index = n),
                      splashFactory: NoSplash.splashFactory,
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: n == _index ? Snag.ink : Colors.transparent,
                              width: 6,
                            ),
                          ),
                        ),
                        child: Text(
                          tabs[n].$2,
                          style: Snag.label(size: 13, color: n == _index ? Snag.ink : Snag.inkSoft),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
