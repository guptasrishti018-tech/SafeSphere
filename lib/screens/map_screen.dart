import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'sos_screen.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'dart:math';
import 'full_map_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;

  LatLng currentPosition = const LatLng(28.6139, 77.2090);

  String locationText = "Getting your current address...";

  Set<Marker> markers = {};

  Set<Polyline> polylines = {};
  LatLng? destinationPosition;
  double safetyScore = 0;
  double routeDistance = 0;
  double routeDuration = 0;

  String safetyStatus = "Not Calculated";

  int policeCount = 0;

  int hospitalCount = 0;

  final TextEditingController destinationController = TextEditingController();

  String riskLevel = "Medium";

  String recommendation = "Analyzing current location...";
  String policeCoverage = "Good";
  String hospitalAccess = "Good";
  String nightSafety = "Moderate";
  String crowdDensity = "High";
  String emergencySupport = "Available";
  int policeNearby = 0;
  int hospitalNearby = 0;
  int petrolNearby = 0;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          locationText = "Location Service Disabled";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationText = "Location Permission Denied";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng liveLocation = LatLng(position.latitude, position.longitude);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;

      String address =
          "${place.locality ?? "Unknown Area"}, "
          "${place.administrativeArea ?? ""}, "
          "${place.country ?? ""}";

      setState(() {
        currentPosition = liveLocation;

        locationText = address;

        markers = {
          Marker(
            markerId: const MarkerId("currentLocation"),
            position: liveLocation,
            infoWindow: const InfoWindow(title: "My Current Location"),
          ),
        };
        safetyScore = 80;

        riskLevel = "Low";

        recommendation =
            "GPS active.\n"
            "Current area appears safe.\n"
            "Emergency services are available nearby.";
      });

      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: liveLocation, zoom: 16),
        ),
      );
    } catch (e) {
      setState(() {
        locationText = "Error: $e";
      });
    }
  }

  Future<void> findNearbyPlaces(String type) async {
    String query = "";

    if (type == "hospital") {
      query = '''
[out:json];
node["amenity"="hospital"](
around:5000,
${currentPosition.latitude},
${currentPosition.longitude}
);
out body;
''';
    } else if (type == "police") {
      query = '''
[out:json];
node["amenity"="police"](
around:5000,
${currentPosition.latitude},
${currentPosition.longitude}
);
out body;
''';
    } else if (type == "petrol") {
      query = '''
[out:json];
node["amenity"="fuel"](
around:5000,
${currentPosition.latitude},
${currentPosition.longitude}
);
out body;
''';
    }
    print("QUERY = ");
    print(query);
    try {
      print("URL = https://overpass-api.de/api/interpreter");
      final response = await http.post(
        Uri.parse("https://overpass.kumi.systems/api/interpreter"),
        body: {"data": query},
      );
      print(response.statusCode);
      print(response.body);

      print("STATUS CODE = ${response.statusCode}");
      print("RESPONSE = ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("FOUND = ${data["elements"].length}");
        int total = data["elements"].length;
        print("TYPE = $type");
        print("TOTAL = $total");

        if (type == "police") {
          policeNearby = total;
        }

        if (type == "hospital") {
          hospitalNearby = total;
        }

        if (type == "petrol") {
          petrolNearby = total;
        }

        Set<Marker> newMarkers = {
          Marker(
            markerId: const MarkerId("currentLocation"),
            position: currentPosition,
            infoWindow: const InfoWindow(title: "My Current Location"),
          ),
        };
        calculateSafetyScore();

        for (var place in data["elements"]) {
          newMarkers.add(
            Marker(
              markerId: MarkerId(place["id"].toString()),
              position: LatLng(
                place["lat"].toDouble(),
                place["lon"].toDouble(),
              ),
              infoWindow: InfoWindow(
                title: place["tags"]?["name"] ?? type.toUpperCase(),
              ),
            ),
          );
        }

        setState(() {
          markers = newMarkers;
        });
        if (type == "police") {
          policeCount = newMarkers.length - 1;
        }

        if (type == "hospital") {
          hospitalCount = newMarkers.length - 1;
        }

        calculateSafetyScore();
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(currentPosition, 12),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${newMarkers.length - 1} nearby $type found"),
          ),
        );
      } else {
        print("API ERROR");
      }
    } catch (e) {
      print("EXCEPTION = $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.travel_explore,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),

                      const SizedBox(width: 15),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "SafeSphere Explorer",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 4),

                            Text(
                              "Explore Smart • Travel Safe",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoChip(Icons.location_on, "GPS", Colors.green),

                      _infoChip(Icons.security, "Safe", Colors.blue),

                      _infoChip(Icons.map, "Maps", Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: destinationController,
              decoration: InputDecoration(
                hintText: "Enter Destination (e.g. Taj Mahal)",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.route),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.route),
              label: const Text(
                "Safe Route",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () async {
                if (destinationController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a destination")),
                  );
                  return;
                }

                await getSafeRoute();
              },
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Quick Destinations",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              _destinationCard(
                icon: Icons.local_hotel,
                title: "Hotels",
                color: Colors.blue,
                onTap: () => findNearbyPlaces("hotel"),
              ),

              _destinationCard(
                icon: Icons.restaurant,
                title: "Food",
                color: Colors.orange,
                onTap: () => findNearbyPlaces("restaurant"),
              ),

              _destinationCard(
                icon: Icons.local_gas_station,
                title: "Petrol",
                color: Colors.red,
                onTap: () => findNearbyPlaces("petrol"),
              ),

              _destinationCard(
                icon: Icons.local_hospital,
                title: "Hospital",
                color: Colors.green,
                onTap: () => findNearbyPlaces("hospital"),
              ),

              _destinationCard(
                icon: Icons.local_police,
                title: "Police",
                color: Colors.indigo,
                onTap: () => findNearbyPlaces("police"),
              ),

              _destinationCard(
                icon: Icons.atm,
                title: "ATM",
                color: Colors.purple,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 20),
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield, color: Colors.green, size: 28),
                      SizedBox(width: 10),
                      Text(
                        "AI Risk Factors",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 25),

                  ListTile(
                    leading: const Icon(
                      Icons.local_police,
                      color: Colors.indigo,
                    ),
                    title: const Text("Police Coverage"),
                    trailing: Text(
                      policeCoverage,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.local_hospital,
                      color: Colors.red,
                    ),
                    title: const Text("Hospital Access"),
                    trailing: Text(
                      hospitalAccess,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.nightlight_round,
                      color: Colors.orange,
                    ),
                    title: const Text("Night Safety"),
                    trailing: Text(
                      nightSafety,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.groups, color: Colors.blue),
                    title: const Text("Crowd Density"),
                    trailing: Text(
                      crowdDensity,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.support_agent,
                      color: Colors.green,
                    ),
                    title: const Text("Emergency Support"),
                    trailing: Text(
                      emergencySupport,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: MediaQuery.of(context).size.height * 0.80,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: currentPosition,
                    zoom: 16,
                  ),
                  markers: markers,
                  polylines: polylines,
                  onMapCreated: (controller) {
                    mapController = controller;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),

                Positioned(
                  top: 10,
                  right: 10,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => FullMapScreen(
                                currentPosition: currentPosition,
                                destinationPosition: destinationPosition,
                                markers: markers,
                                polylines: polylines,
                                distance: routeDistance,
                                eta: routeDuration,
                                safetyScore: safetyScore,
                              ),
                        ),
                      );
                    },
                    child: const Icon(Icons.fullscreen),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🤖 AI Route Analysis",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: safetyScore / 100,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(20),
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      safetyScore >= 80
                          ? Colors.green
                          : safetyScore >= 60
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Safety Score : ${safetyScore.toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    "Risk Level : $riskLevel",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.route, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Distance : ${routeDistance.toStringAsFixed(2)} km",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "ETA : ${routeDuration.toStringAsFixed(0)} min",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Text(
                    "🚓 Police Nearby : $policeNearby",
                    style: const TextStyle(fontSize: 16),
                  ),

                  Text(
                    "🏥 Hospital Nearby : $hospitalNearby",
                    style: const TextStyle(fontSize: 16),
                  ),

                  Text(
                    "⛽ Petrol Pumps : $petrolNearby",
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    recommendation,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Current Location",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          locationText,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 18,
                            ),

                            const SizedBox(width: 6),

                            const Text(
                              "Live GPS Connected",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await getCurrentLocation();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Location Updated Successfully"),
                  ),
                );
              },
              icon: const Icon(Icons.my_location),
              label: const Text("Get Current Location"),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await findNearbyPlaces("police");
              },
              icon: const Icon(Icons.local_police),
              label: const Text("Find Nearby Police Stations"),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await findNearbyPlaces("hospital");
              },
              icon: const Icon(Icons.local_hospital),
              label: const Text("Find Nearby Hospitals"),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SosScreen()),
                );
              },
              icon: const Icon(Icons.warning),
              label: const Text(
                "SOS EMERGENCY",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),

          const SizedBox(width: 6),

          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _analysisChip(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 4),

          Text(title),
        ],
      ),
    );
  }

  Future<void> getSafeRoute() async {
    try {
      List<Location> locations = await locationFromAddress(
        destinationController.text.trim(),
      );

      if (locations.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Destination not found")));
        return;
      }

      LatLng destination = LatLng(
        locations.first.latitude,
        locations.first.longitude,
      );
      destinationPosition = destination;

      setState(() {
        markers.add(
          Marker(
            markerId: const MarkerId("destination"),
            position: destination,
            infoWindow: InfoWindow(title: destinationController.text),
          ),
        );
      });

      await drawRoute(destination);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Destination Found Successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> drawRoute(LatLng destination) async {
    try {
      final url = Uri.parse(
        "https://router.project-osrm.org/route/v1/driving/"
        "${currentPosition.longitude},${currentPosition.latitude};"
        "${destination.longitude},${destination.latitude}"
        "?overview=full&geometries=geojson",
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Unable to fetch route")));
        return;
      }

      final data = json.decode(response.body);
      double distance = data["routes"][0]["distance"] / 1000;

      double duration = data["routes"][0]["duration"] / 60;

      final coordinates = data["routes"][0]["geometry"]["coordinates"] as List;

      List<LatLng> routePoints = [];

      for (var point in coordinates) {
        routePoints.add(LatLng(point[1].toDouble(), point[0].toDouble()));
      }

      setState(() {
        routeDistance = distance;
        routeDuration = duration;
        polylines.clear();

        polylines.add(
          Polyline(
            polylineId: const PolylineId("safeRoute"),
            points: routePoints,
            color: Colors.blue,
            width: 6,
          ),
        );
      });
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          min(currentPosition.latitude, destination.latitude),
          min(currentPosition.longitude, destination.longitude),
        ),
        northeast: LatLng(
          max(currentPosition.latitude, destination.latitude),
          max(currentPosition.longitude, destination.longitude),
        ),
      );

      mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Route Error: $e")));
    }
  }

  void calculateSafetyScore() {
    double score = 40.0;

    score += policeNearby * 8;
    score += hospitalNearby * 6;
    score += petrolNearby * 3;

    if (score > 100) {
      score = 100.0;
    }

    String risk;
    String advice;

    if (score >= 80) {
      risk = "Low";
      advice =
          "Area looks safe.\nPolice and emergency services are available nearby.";
    } else if (score >= 60) {
      risk = "Medium";
      advice = "Travel carefully.\nKeep emergency contacts ready.";
    } else {
      risk = "High";
      advice = "Avoid travelling alone.\nUse SOS if required.";
    }

    setState(() {
      safetyScore = score;
      riskLevel = risk;
      recommendation = advice;

      policeCoverage = policeNearby > 0 ? "Good" : "Low";
      hospitalAccess = hospitalNearby > 0 ? "Good" : "Low";
      emergencySupport = score >= 70 ? "Available" : "Limited";
      crowdDensity = score >= 70 ? "High" : "Low";
      nightSafety = score >= 70 ? "Safe" : "Moderate";
    });
  }

  Widget _destinationCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),

            const SizedBox(height: 10),

            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
