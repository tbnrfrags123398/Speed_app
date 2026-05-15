import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ScooterHud extends StatefulWidget {
  final double currentSpeed;
  final int? speedLimit;
  final LatLng? currentLatLng;

  final double? heading;

  final double tripDistanceMiles;
  final int tripSeconds;
  final double avgSpeedMph;
  final double maxSpeedMph;

  final bool isNight;
  final bool batterySaver;

  final VoidCallback onResetTrip;
  final VoidCallback onToggleBatterySaver;

  const ScooterHud({
    super.key,
    required this.currentSpeed,
    required this.speedLimit,
    required this.currentLatLng,
    required this.heading,
    required this.tripDistanceMiles,
    required this.tripSeconds,
    required this.avgSpeedMph,
    required this.maxSpeedMph,
    required this.isNight,
    required this.batterySaver,
    required this.onResetTrip,
    required this.onToggleBatterySaver,
  });

  @override
  State<ScooterHud> createState() => _ScooterHudState();
}

class _ScooterHudState extends State<ScooterHud> {
  bool mapExpanded = false;

  static const String _neonMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#1a1a1a"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#000000"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#ff0044"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#001f3f"}]
    },
    {
      "featureType": "poi",
      "elementType": "geometry",
      "stylers": [{"color": "#111111"}]
    }
  ]
  ''';

  String _headingText() {
    final h = widget.heading ?? 0.0;
    final deg = (h % 360 + 360) % 360;
    if (deg >= 337.5 || deg < 22.5) return "N";
    if (deg < 67.5) return "NE";
    if (deg < 112.5) return "E";
    if (deg < 157.5) return "SE";
    if (deg < 202.5) return "S";
    if (deg < 247.5) return "SW";
    if (deg < 292.5) return "W";
    return "NW";
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return "${h}h ${m}m";
    } else if (m > 0) {
      return "${m}m ${s}s";
    } else {
      return "${s}s";
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSpeeding =
        widget.speedLimit != null && widget.currentSpeed > widget.speedLimit!;

    final Color mphColor =
        isSpeeding ? Colors.red : Colors.white;
    final Color mphGlow =
        isSpeeding ? Colors.redAccent : Colors.blueAccent;

    return Stack(
      children: [
        // FULLSCREEN MAP WHEN EXPANDED (if not in battery saver)
        if (mapExpanded &&
            widget.currentLatLng != null &&
            !widget.batterySaver)
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.currentLatLng!,
                zoom: 17,
              ),
              onMapCreated: (controller) {
                controller.setMapStyle(_neonMapStyle);
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              trafficEnabled: false,
              buildingsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),

        if (mapExpanded && !widget.batterySaver)
          Container(
            color: Colors.black.withOpacity(0.25),
          ),

        // HUD CONTENT
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.speedLimit != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Text(
                    "${widget.speedLimit!}",
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSpeeding
                      ? Colors.red.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.currentSpeed.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 160,
                    fontWeight: FontWeight.w900,
                    color: mphColor,
                    shadows: [
                      Shadow(
                        color: mphGlow,
                        blurRadius: 20,
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "MPH",
                style: TextStyle(
                  fontSize: 40,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        // COMPASS (top-left)
        Positioned(
          top: 40,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.explore, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  _headingText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // TRIP METER (bottom-left)
        Positioned(
          bottom: 30,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Trip: ${widget.tripDistanceMiles.toStringAsFixed(2)} mi",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  "Time: ${_formatTime(widget.tripSeconds)}",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  "Avg: ${widget.avgSpeedMph.toStringAsFixed(1)} mph",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  "Max: ${widget.maxSpeedMph.toStringAsFixed(0)} mph",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: widget.onResetTrip,
                  child: const Text(
                    "Reset",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // FLOATING MINI-MAP (150x150) - bottom-right (disabled in battery saver)
        if (!mapExpanded &&
            widget.currentLatLng != null &&
            !widget.batterySaver)
          Positioned(
            bottom: 30,
            right: 30,
            child: GestureDetector(
              onTap: () {
                setState(() => mapExpanded = true);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blueAccent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.currentLatLng!,
                      zoom: 16,
                    ),
                    onMapCreated: (controller) {
                      controller.setMapStyle(_neonMapStyle);
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    trafficEnabled: false,
                    buildingsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),
              ),
            ),
          ),

        // TAP TO EXIT FULLSCREEN MAP
        if (mapExpanded && !widget.batterySaver)
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () {
                setState(() => mapExpanded = false);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),

        // BOTTOM-CENTER NEON RED SETTINGS ORB
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.black87,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              "Bike HUD Settings",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Battery Saver (no map)",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Switch(
                                value: widget.batterySaver,
                                activeColor: Colors.redAccent,
                                onChanged: (_) {
                                  Navigator.of(context).pop();
                                  widget.onToggleBatterySaver();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Day/Night mode is automatic based on time.",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.8),
                      blurRadius: 25,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
