import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global.dart';
import 'ai_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String cityName = "Loading...";
  String attractionName = "Loading...";
  String weather = "Loading...";
  String temperature = "--";
  String currentLocation = "Getting Location...";
  String aiSuggestion = "Loading travel suggestion...";
  String selectedLanguage = "English";

  String attraction1 = "Loading...";
  String attraction2 = "Loading...";
  String attraction3 = "Loading...";

  @override
  void initState() {
    super.initState();
    loadLanguage();
    loadUserName();
    getWeather();
    getCurrentLocation();
  }

  Future<void> getWeather() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final url =
          "https://api.openweathermap.org/data/2.5/weather"
          "?lat=${position.latitude}"
          "&lon=${position.longitude}"
          "&appid=2ab65a10eaefe22da53dbf54157fd8af"
          "&units=metric";

      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      setState(() {
        temperature = data["main"]["temp"].round().toString();
        weather = data["weather"][0]["main"];
      });
    } catch (e) {
      debugPrint("Weather Error: $e");
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;

      setState(() {
        currentLocation =
            "${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
      });

      updateTravelSuggestion();
      getAIAttractions();
    } catch (e) {
      debugPrint("Location Error: $e");
    }
  }

  Future<void> getAIAttractions() async {
    String location = currentLocation.toLowerCase();

    setState(() {
      if (location.contains("meerut")) {
        attraction1 = "Augarnath Temple";
        attraction2 = "Gandhi Bagh";
        attraction3 = "Suraj Kund Park";
      } else if (location.contains("agra")) {
        attraction1 = "Taj Mahal";
        attraction2 = "Agra Fort";
        attraction3 = "Mehtab Bagh";
      } else if (location.contains("delhi")) {
        attraction1 = "India Gate";
        attraction2 = "Red Fort";
        attraction3 = "Qutub Minar";
      } else if (location.contains("lucknow")) {
        attraction1 = "Bara Imambara";
        attraction2 = "Rumi Darwaza";
        attraction3 = "Ambedkar Park";
      } else if (location.contains("jaipur")) {
        attraction1 = "Hawa Mahal";
        attraction2 = "Amber Fort";
        attraction3 = "City Palace";
      } else if (location.contains("varanasi")) {
        attraction1 = "Kashi Vishwanath";
        attraction2 = "Dashashwamedh Ghat";
        attraction3 = "Sarnath";
      } else {
        attraction1 = "Popular Attraction 1";
        attraction2 = "Popular Attraction 2";
        attraction3 = "Popular Attraction 3";
      }
    });
  }

  void updateTravelSuggestion() {
    String city = currentLocation.toLowerCase();

    if (city.contains("agra")) {
      aiSuggestion =
          "Visit Taj Mahal before 10 AM and Agra Fort in the evening.";
    } else if (city.contains("jaipur")) {
      aiSuggestion = "Explore Hawa Mahal and Amer Fort. Best time: Morning.";
    } else if (city.contains("delhi")) {
      aiSuggestion = "Visit India Gate, Red Fort and Qutub Minar today.";
    } else {
      aiSuggestion = "Explore popular attractions near your current location.";
    }
  }

  Future<void> saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("language", language);
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    String? savedLanguage = prefs.getString("language");

    if (savedLanguage != null) {
      setState(() {
        selectedLanguage = savedLanguage;
        AppData.selectedLanguage = savedLanguage;
      });
    }
  }

  Future<void> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      AppData.userName = prefs.getString("name") ?? "Traveler";
    });
  }

  Future<void> makeCall(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Widget buildCard(IconData icon, String title, String subtitle, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget quickButton(IconData icon, String title, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 8),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(.12),
              child: Icon(icon, color: color, size: 26),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),

            const SizedBox(height: 6),

            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLanguageCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.language, color: Colors.blue),
        title: const Text("Language"),
        trailing: DropdownButton<String>(
          value: selectedLanguage,
          underline: const SizedBox(),
          items:
              AppData.languages.map((lang) {
                return DropdownMenuItem<String>(value: lang, child: Text(lang));
              }).toList(),
          onChanged: (value) {
            setState(() {
              selectedLanguage = value!;
              AppData.selectedLanguage = value;
            });

            saveLanguage(value!);
          },
        ),
      ),
    );
  }

  Widget emergencyCard() {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "🚨 Emergency Contacts",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            ListTile(
              leading: const Icon(Icons.local_police),
              title: const Text("Police"),
              subtitle: const Text("112"),
              onTap: () => makeCall("112"),
            ),

            ListTile(
              leading: const Icon(Icons.local_hospital),
              title: const Text("Ambulance"),
              subtitle: const Text("108"),
              onTap: () => makeCall("108"),
            ),

            ListTile(
              leading: const Icon(Icons.woman),
              title: const Text("Women Helpline"),
              subtitle: const Text("1091"),
              onTap: () => makeCall("1091"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              height: 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1565C0),
                    Color(0xFF1E88E5),
                    Color(0xFF42A5F5),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(.25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: Stack(
                children: [
                  Positioned(
                    top: -40,
                    right: -30,
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.white.withOpacity(.08),
                    ),
                  ),

                  Positioned(
                    right: 12,
                    top: 12,
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Good Afternoon 👋",
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          AppData.userName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          "Travel Smart • Travel Safe",
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),

                        const Spacer(),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.15),
                            borderRadius: BorderRadius.circular(30),
                          ),

                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 20,
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Text(
                                  currentLocation,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              const Icon(
                                Icons.verified_user,
                                color: Colors.greenAccent,
                                size: 20,
                              ),

                              const SizedBox(width: 5),

                              const Text(
                                "Safe Zone",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                summaryCard(
                  icon: Icons.location_on,
                  title: "Location",
                  value: currentLocation,
                  color: Colors.red,
                ),

                summaryCard(
                  icon: Icons.cloud,
                  title: "Weather",
                  value: "$temperature°C",
                  color: Colors.orange,
                ),
              ],
            ),

            Row(
              children: [
                summaryCard(
                  icon: Icons.security,
                  title: "Safety",
                  value: "Safe",
                  color: Colors.green,
                ),

                summaryCard(
                  icon: Icons.verified,
                  title: "Digital ID",
                  value: "Verified",
                  color: Colors.blue,
                ),
              ],
            ),

            const SizedBox(height: 15),

            buildLanguageCard(),

            const SizedBox(height: 10),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Quick Access",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            Row(
              children: [
                quickButton(Icons.local_hospital, "Hospital", Colors.red),
                quickButton(Icons.local_police, "Police", Colors.blue),
              ],
            ),

            Row(
              children: [
                quickButton(Icons.local_gas_station, "Petrol", Colors.orange),
                quickButton(Icons.medical_services, "Medical", Colors.green),
              ],
            ),

            const SizedBox(height: 20),

            buildCard(
              Icons.hotel,
              AppData.tr("Nearby Hotels", {"हिन्दी": "नजदीक के होटल"}),
              "24 Hotels Found",
              Colors.indigo,
            ),

            buildCard(
              Icons.restaurant,
              AppData.tr("Nearby Restaurants", {"हिन्दी": "नजदीक के रेस्तरां"}),
              "31 Restaurants Found",
              Colors.deepOrange,
            ),
            buildCard(
              Icons.account_balance,
              AppData.tr("Popular Attraction", {"हिन्दी": "लोकप्रिय आकर्षण"}),
              attraction1,
              Colors.teal,
            ),

            buildCard(
              Icons.fort,
              AppData.tr("Historical Places", {"हिन्दी": "ऐतिहासिक स्थान"}),
              attraction2,
              Colors.brown,
            ),

            buildCard(
              Icons.park,
              AppData.tr("Parks", {"हिन्दी": "पार्क"}),
              attraction3,
              Colors.green,
            ),

            buildCard(
              Icons.directions_bus,
              AppData.tr("Transport Availability", {
                "हिन्दी": "परिवहन उपलब्धता",
              }),
              "Taxi, Auto, Uber Available",
              Colors.brown,
            ),

            const SizedBox(height: 20),

            emergencyCard(),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                aiSuggestion,
                style: const TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiScreen()),
                  );
                },
                icon: const Icon(Icons.flight_takeoff),
                label: const Text("Plan My Trip"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
