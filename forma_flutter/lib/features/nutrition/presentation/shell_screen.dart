import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../app/widgets/gradient_backdrop.dart';
import '../../settings/presentation/mistral_settings_screen.dart';
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

  Future<void> _openMistralSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const MistralSettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const HomeScreen(),
      const TrendsScreen(),
    ];
    final Size screenSize = MediaQuery.sizeOf(context);
    final bool isLandscape = screenSize.width > screenSize.height;
    final bool useRail =
        screenSize.width >= AppBreakpoints.medium ||
        (isLandscape && screenSize.width >= AppBreakpoints.compact);
    final String title = _index == 0 ? 'Meal Logger' : 'Calorie Trends';
    final Widget activePage = AnimatedSwitcher(
      duration: AppDurations.short,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: ValueKey<int>(_index), child: pages[_index]),
    );

    return GradientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            IconButton(
              tooltip: 'Mistral settings',
              onPressed: _openMistralSettings,
              icon: const Icon(Icons.vpn_key_rounded),
            ),
          ],
        ),
        body:
            useRail
                ? Row(
                  children: <Widget>[
                    NavigationRail(
                      selectedIndex: _index,
                      extended: screenSize.width >= AppBreakpoints.large,
                      labelType:
                          screenSize.width >= AppBreakpoints.large
                              ? null
                              : NavigationRailLabelType.all,
                      destinations: const <NavigationRailDestination>[
                        NavigationRailDestination(
                          icon: Icon(Icons.edit_note_rounded),
                          selectedIcon: Icon(Icons.edit_note_rounded),
                          label: Text('Log'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.show_chart_rounded),
                          selectedIcon: Icon(Icons.show_chart_rounded),
                          label: Text('Trends'),
                        ),
                      ],
                      onDestinationSelected: (int value) {
                        setState(() {
                          _index = value;
                        });
                      },
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: activePage),
                  ],
                )
                : activePage,
        bottomNavigationBar:
            useRail
                ? null
                : NavigationBar(
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
