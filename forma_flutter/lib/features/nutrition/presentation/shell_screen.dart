import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../app/widgets/gradient_backdrop.dart';
import '../../settings/application/api_key_controller.dart';
import 'home_screen.dart';
import 'trends_screen.dart';

class NutritionShellScreen extends ConsumerStatefulWidget {
  const NutritionShellScreen({super.key});

  @override
  ConsumerState<NutritionShellScreen> createState() =>
      _NutritionShellScreenState();
}

class _NutritionShellScreenState extends ConsumerState<NutritionShellScreen> {
  int _index = 0;

  Future<void> _confirmResetKey() async {
    final bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset API Key?'),
          content: const Text(
            'This signs out from Mistral until you enter a key again.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) {
      return;
    }

    await ref.read(apiKeyControllerProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const HomeScreen(),
      const TrendsScreen(),
    ];
    final String title = _index == 0 ? 'Meal Logger' : 'Calorie Trends';

    return GradientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            IconButton(
              tooltip: 'Reset API key',
              onPressed: _confirmResetKey,
              icon: const Icon(Icons.vpn_key_rounded),
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: AppDurations.short,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(key: ValueKey<int>(_index), child: pages[_index]),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.edit_note_rounded),
              selectedIcon: Icon(Icons.edit_note_rounded),
              label: 'Log',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart_rounded),
              selectedIcon: Icon(Icons.show_chart_rounded),
              label: 'Trends',
            ),
          ],
          onDestinationSelected: (int value) {
            setState(() {
              _index = value;
            });
          },
        ),
      ),
    );
  }
}
