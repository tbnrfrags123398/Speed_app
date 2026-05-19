import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final bool testMode;
  final bool batterySaver;
  final String mapStyle; // light / dark / satellite
  final bool voiceAlerts;
  final bool simpleDisplay; // ⭐ NEW

  const SettingsScreen({
    super.key,
    required this.testMode,
    required this.batterySaver,
    required this.mapStyle,
    required this.voiceAlerts,
    required this.simpleDisplay, // ⭐ NEW
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool testMode;
  late bool batterySaver;
  late String mapStyle;
  late bool voiceAlerts;
  late bool simpleDisplay; // ⭐ NEW

  @override
  void initState() {
    super.initState();
    testMode = widget.testMode;
    batterySaver = widget.batterySaver;
    mapStyle = widget.mapStyle;
    voiceAlerts = widget.voiceAlerts;
    simpleDisplay = widget.simpleDisplay; // ⭐ NEW
  }

  void _saveAndExit() {
    Navigator.pop(context, {
      "testMode": testMode,
      "batterySaver": batterySaver,
      "mapStyle": mapStyle,
      "voiceAlerts": voiceAlerts,
      "simpleDisplay": simpleDisplay, // ⭐ NEW
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
              style: TextStyle(color: Colors.cyanAccent, fontSize: 16),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          // ⭐ TEST MODE
          SwitchListTile(
            title: const Text(
              "Test Mode",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Simulate speed + speed limits indoors",
              style: TextStyle(color: Colors.white70),
            ),
            value: testMode,
            onChanged: (value) {
              setState(() => testMode = value);
            },
            activeColor: Colors.cyanAccent,
          ),

          // ⭐ BATTERY SAVER
          SwitchListTile(
            title: const Text(
              "Battery Saver",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Reduce animations + voice alerts",
              style: TextStyle(color: Colors.white70),
            ),
            value: batterySaver,
            onChanged: (value) {
              setState(() => batterySaver = value);
            },
            activeColor: Colors.greenAccent,
          ),

          // ⭐ SIMPLE DISPLAY (NEW)
          SwitchListTile(
            title: const Text(
              "Simple Display",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Minimal HUD like classic GPS speed apps",
              style: TextStyle(color: Colors.white70),
            ),
            value: simpleDisplay,
            onChanged: (value) {
              setState(() => simpleDisplay = value);
            },
            activeColor: Colors.blueAccent,
          ),

          const Divider(color: Colors.white24),

          // ⭐ MAP STYLE
          ListTile(
            title: const Text(
              "Map Style",
              style: TextStyle(color: Colors.white),
            ),
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

          const Divider(color: Colors.white24),

          // ⭐ VOICE ALERTS
          SwitchListTile(
            title: const Text(
              "Voice Alerts",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Speeding, speed limit changes, GPS lost/restored",
              style: TextStyle(color: Colors.white70),
            ),
            value: voiceAlerts,
            onChanged: (value) {
              setState(() => voiceAlerts = value);
            },
            activeColor: Colors.orangeAccent,
          ),

          const SizedBox(height: 20),

          // ⭐ HUD COLOR PREVIEW
          Center(
            child: Column(
              children: [
                const Text(
                  "HUD Color Preview",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 140,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.cyanAccent,
                        Colors.blueAccent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Bike HUD",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 140,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.redAccent,
                        Colors.orangeAccent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent,
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Car HUD",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

