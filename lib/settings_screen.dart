import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final bool testMode;
  final bool batterySaver;

  final VoidCallback onToggleTestMode;
  final VoidCallback onToggleBatterySaver;

  const SettingsScreen({
    super.key,
    required this.testMode,
    required this.batterySaver,
    required this.onToggleTestMode,
    required this.onToggleBatterySaver,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          // ⭐ TEST MODE
          SwitchListTile(
            title: const Text("Test Mode",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text("Simulate speed + speed limits indoors",
                style: TextStyle(color: Colors.white70)),
            value: testMode,
            onChanged: (_) => onToggleTestMode(),
            activeColor: Colors.orange,
          ),

          // ⭐ BATTERY SAVER
          SwitchListTile(
            title: const Text("Battery Saver",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text("Reduce animations + dim colors",
                style: TextStyle(color: Colors.white70)),
            value: batterySaver,
            onChanged: (_) => onToggleBatterySaver(),
            activeColor: Colors.green,
          ),

          const Divider(color: Colors.white24),

          // ⭐ FUTURE OPTIONS
          ListTile(
            title: const Text("Map Style",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text("Coming soon",
                style: TextStyle(color: Colors.white54)),
            trailing: const Icon(Icons.map, color: Colors.white),
          ),

          ListTile(
            title: const Text("Voice Alerts",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text("Coming soon",
                style: TextStyle(color: Colors.white54)),
            trailing: const Icon(Icons.volume_up, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
