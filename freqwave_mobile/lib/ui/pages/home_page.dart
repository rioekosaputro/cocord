import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/background_service.dart';
import '../../core/radio/radio_controller.dart';
import '../theme.dart';
import '../widgets/status_bar.dart';
import 'chat_page.dart';
import 'radio_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  void _select(int i) {
    final radio = context.read<RadioController>();
    if (i == 1) {
      radio.openChat();
    } else {
      radio.closeChat();
    }
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.select<RadioController, int>((r) => r.unread);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) BackgroundService.minimize();
      },
      child: Scaffold(
        appBar: AppBar(title: const StatusBar()),
        body: SafeArea(
          child: IndexedStack(
            index: _tab,
            children: const [RadioPage(), ChatPage(), SettingsPage()],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _select,
          destinations: [
            const NavigationDestination(
                icon: Icon(Icons.headset_mic), label: 'Voice'),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unread > 0 && _tab != 1,
                label: Text('$unread'),
                backgroundColor: AppColors.red,
                child: const Icon(Icons.forum_outlined),
              ),
              label: 'Chat',
            ),
            const NavigationDestination(
                icon: Icon(Icons.tune), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
