import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'sos_screen.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

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
  int safetyScore = 40;

  String riskLevel = "Medium";

  String recommendation = "Analyzing current location...";

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
    }
    print("QUERY = ");
    print(query);
    try {
      print("URL = https://overpass-api.de/api/interpreter");
      final response = await http.post(
        Uri.parse("https://lz4.overpass-api.de/api/interpreter"),
        body: {"data": query},
      );

      print("STATUS CODE = ${response.statusCode}");
      print("RESPONSE = ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("FOUND = ${data["elements"].length}");

        Set<Marker> newMarkers = {
          Marker(
            markerId: const MarkerId("currentLocation"),
            position: currentPosition,
            infoWindow: const InfoWindow(title: "My Current Location"),
          ),
        };

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
            child: const TextField(
              decoration: InputDecoration(
                hintText: "Search hotels, police, hospitals...",
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.mic),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 18),
              ),
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
                      Icon(Icons.psychology, color: Colors.deepPurple),

                      SizedBox(width: 10),

                      Text(
                        "AI Safety Analysis",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _analysisChip("Safety", "$safetyScore%", Colors.green),

                      _analysisChip("Risk", riskLevel, Colors.blue),

                      _analysisChip("GPS", "ON", Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "AI Recommendation:\n\n$recommendation",
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(
            height: 380,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: currentPosition,
                  zoom: 14,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                markers: markers,
                onMapCreated: (controller) {
                  mapController = controller;
                },
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
