import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../app/widgets/gradient_backdrop.dart';
import '../application/daily_feedback_controller.dart';
import '../../settings/presentation/mistral_settings_screen.dart';
import 'home_screen.dart';
import 'trends_screen.dart';

class NutritionShellScreen extends ConsumerStatefulWidget {
  const NutritionShellScreen({super.key});

  @override
  ConsumerState<NutritionShellScreen> createState() =>
      _NutritionShellScreenState();
}

class _NutritionShellScreenState extends ConsumerState<NutritionShellScreen>
    with WidgetsBindingObserver {
  int _index = 0;
  Timer? _midnightSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleNextMidnightSync();
    _triggerDailyFeedbackSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleNextMidnightSync();
      _triggerDailyFeedbackSync();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> _openMistralSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const MistralSettingsScreen(),
      ),
    );
  }

  void _scheduleNextMidnightSync() {
    _midnightSyncTimer?.cancel();
    final DateTime now = DateTime.now();
    final DateTime nextMidnight = DateTime(
      now.year,
      now.month,
      now.day + 1,
      0,
      3,
    );
    final Duration wait = nextMidnight.difference(now);
    _midnightSyncTimer = Timer(wait, () {
      _triggerDailyFeedbackSync();
      _scheduleNextMidnightSync();
    });
  }

  void _triggerDailyFeedbackSync() {
    unawaited(
      ref.read(dailyFeedbackControllerProvider).syncPendingEndOfDayFeedback(),
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
      duration: AppDurations.medium,
      switchInCurve: AppCurves.entrance,
      switchOutCurve: AppCurves.exit,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final Animation<double> fade = CurvedAnimation(
          parent: animation,
          curve: AppCurves.standard,
        );
        final Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: AppCurves.entrance),
        );
        final Animation<double> scale = Tween<double>(
          begin: 0.985,
          end: 1,
        ).animate(
          CurvedAnimation(parent: animation, curve: AppCurves.entrance),
        );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(scale: scale, child: child),
          ),
        );
      },
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
