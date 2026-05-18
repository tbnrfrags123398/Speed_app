import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final bool testMode;
  final bool batterySaver;
  final String mode;
  final String mapStyle; // light / dark / satellite
  final bool voiceAlerts;

  const SettingsScreen({
    super.key,
    required this.testMode,
    required this.batterySaver,
    required this.mode,
    required this.mapStyle,
    required this.voiceAlerts,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool testMode;
  late bool batterySaver;
  late String mode;
  late String mapStyle;
  late bool voiceAlerts;

  @override
  void initState() {
    super.initState();
    testMode = widget.testMode;
    batterySaver = widget.batterySaver;
    mode = widget.mode;
    mapStyle = widget.mapStyle;
    voiceAlerts = widget.voiceAlerts;
  }

  void _saveAndExit() {
    Navigator.pop(context, {
      "testMode": testMode,
      "batterySaver": batterySaver,
      "mode": mode,
      "mapStyle": mapStyle,
      "voiceAlerts": voiceAlerts,
    });
  }

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
        actions: [
          TextButton(
            onPressed: _saveAndExit,
            child: const Text(
              "SAVE",
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // ⭐ MODE SELECTOR
          ListTile(
            title: const Text("Mode", style: TextStyle(color: Colors.white)),
            subtitle: Text(
              mode == "bike" ? "Bike HUD" : "Car HUD",
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: DropdownButton<String>(
              dropdownColor: Colors.black,
              value: mode,
              items: const [
                DropdownMenuItem(
                  value: "bike",
                  child: Text("Bike", style: TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: "car",
                  child: Text("Car", style: TextStyle(color: Colors.white)),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => mode = value);
              },
            ),
          ),

          const Divider(color: Colors.white24),

          // ⭐ TEST MODE
          SwitchListTile(
            title: const Text("Test Mode",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              "Simulate speed + speed limits indoors",
              style: TextStyle(color: Colors.white70),
            ),
            value: testMode,
            onChanged: (value) {
              setState(() => testMode = value);
            },
            activeColor: Colors.orange,
          ),

          // ⭐ BATTERY SAVER
          SwitchListTile(
            title: const Text("Battery Saver",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              "Reduce animations + voice alerts",
              style: TextStyle(color: Colors.white70),
            ),
            value: batterySaver,
            onChanged: (value) {
              setState(() => batterySaver = value);
            },
            activeColor: Colors.green,
          ),

          const Divider(color: Colors.white24),

          // ⭐ MAP STYLE
          ListTile(
            title: const Text("Map Style",
                style: TextStyle(color: Colors.white)),
            subtitle: Text(
              mapStyle == "light"
                  ? "Light"
                  : mapStyle == "dark"
                      ? "Dark"
                      : "Satellite",
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: DropdownButton<String>(
              dropdownColor: Colors.black,
              value: mapStyle,
              items: const [
                DropdownMenuItem(
                  value: "light",
                  child: Text("Light", style: TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: "dark",
                  child: Text("Dark", style: TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: "satellite",
                  child:
                      Text("Satellite", style: TextStyle(color: Colors.white)),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => mapStyle = value);
              },
            ),
          ),

          // ⭐ VOICE ALERTS
          SwitchListTile(
            title: const Text("Voice Alerts",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              "Speeding, speed limit changes, GPS lost/restored",
              style: TextStyle(color: Colors.white70),
            ),
            value: voiceAlerts,
            onChanged: (value) {
              setState(() => voiceAlerts = value);
            },
            activeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}
