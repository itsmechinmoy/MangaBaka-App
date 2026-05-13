import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';

class BackIntent extends Intent {
  const BackIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class SettingsIntent extends Intent {
  const SettingsIntent();
}

class TabIntent extends Intent {
  final int index;
  const TabIntent(this.index);
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}

class AppShortcuts extends StatelessWidget {
  final Widget child;

  const AppShortcuts({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.escape): const BackIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF): const SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma): const SettingsIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.comma): const SettingsIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): const RefreshIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyR): const RefreshIntent(),
        
        // Tab switching
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit1): const TabIntent(0),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit1): const TabIntent(0),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit2): const TabIntent(1),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit2): const TabIntent(1),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit3): const TabIntent(2),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit3): const TabIntent(2),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit4): const TabIntent(3),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit4): const TabIntent(3),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit5): const TabIntent(4),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit5): const TabIntent(4),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          BackIntent: CallbackAction<BackIntent>(
            onInvoke: (intent) {
              final NavigatorState? navigator = Navigator.maybeOf(context);
              if (navigator != null && navigator.canPop()) {
                navigator.pop();
              }
              return null;
            },
          ),
          SettingsIntent: CallbackAction<SettingsIntent>(
            onInvoke: (intent) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              return null;
            },
          ),
          TabIntent: CallbackAction<TabIntent>(
            onInvoke: (intent) {
              MainScreen.setTabIndex(intent.index);
              return null;
            },
          ),
          // Search and Refresh are context-dependent and will be handled in specific screens if needed
          // or we can try to find a way to dispatch them.
        },
        child: child,
      ),
    );
  }
}
