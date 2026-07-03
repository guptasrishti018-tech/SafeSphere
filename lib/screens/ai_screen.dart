import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../global.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final SpeechToText speech = SpeechToText();

  final FlutterTts tts = FlutterTts();

  bool isListening = false;
  bool wasVoiceInput = false;
  final TextEditingController messageController = TextEditingController();

  List<Map<String, String>> messages = [];

  bool isLoading = false;
  bool speakerEnabled = true;
  String currentLocation = "Unknown Location";
  @override
  void initState() {
    super.initState();

    getCurrentLocation();
  }

  // APNI OPENROUTER API KEY YAHAN PASTE KARO
  final String apiKey =
      "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";
  Future<void> startListening() async {
    bool available = await speech.initialize();

    if (available) {
      wasVoiceInput = true;
      setState(() {
        isListening = true;
      });

      speech.listen(
        onResult: (result) {
          setState(() {
            messageController.text = result.recognizedWords;
          });
        },
      );
    }
  }

  Future<void> stopListening() async {
    await speech.stop();

    setState(() {
      isListening = false;
    });
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];

      currentLocation = "${place.locality}, ${place.administrativeArea}";
    } catch (e) {
      print("Location Error: $e");
    }
  }

  Future<void> openNearestHospital() async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=hospital+near+me",
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> sendMessage() async {
    String userMessage = messageController.text.trim();
    String lowerMessage = userMessage.toLowerCase();
    print("CURRENT LOCATION = $currentLocation");
    print("USER MESSAGE = $userMessage");
    if (userMessage.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": userMessage});

      isLoading = true;
    });

    messageController.clear();

    try {
      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "https://safesphere.app",
          "X-Title": "SafeSphere",
        },
        body: jsonEncode({
          "model": "deepseek/deepseek-chat-v3-0324",
          "messages": [
            {
              "role": "system",
              "content":
                  "You are SafeSphere AI, an intelligent travel and safety assistant. "
                  "User current location is $currentLocation. "
                  "Always reply in ${AppData.selectedLanguage} language. "
                  "You help tourists with travel planning, itineraries, safety advice, hotels, restaurants, transport, emergency guidance and local attractions. "
                  "When a user asks to plan a trip, create a complete day-wise itinerary. "
                  "Include places to visit, food recommendations, estimated budget, transport options, best visiting times and safety tips. "
                  "Format the answer clearly with headings like Day 1, Day 2, Budget, Safety Tips and Recommendations. "
                  "Always give detailed and practical answers. "
                  "If a user asks for hotels, restaurants, hospitals, police stations, pharmacies, petrol pumps or tourist attractions, provide recommendations directly inside the app. "
                  "Do not tell users to open Google Maps or any external application. ",
            },
            {"role": "user", "content": userMessage},
          ],
        }),
      );

      print("STATUS CODE = ${response.statusCode}");
      print("BODY = ${response.body}");

      final data = jsonDecode(response.body);

      String aiReply = "No response";

      if (response.statusCode == 200 &&
          data["choices"] != null &&
          data["choices"].isNotEmpty) {
        aiReply = data["choices"][0]["message"]["content"];
        if (wasVoiceInput && speakerEnabled) {
          await tts.speak(aiReply);
        }

        wasVoiceInput = false;
      } else {
        if (response.statusCode == 429) {
          aiReply =
              "⚠️ SafeSphere AI is busy right now. Please try again in a few moments.";
        } else {
          aiReply =
              "⚠️ SafeSphere AI is currently unavailable. Please try again later.";
        }
      }

      setState(() {
        messages.add({"role": "ai", "text": aiReply});

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        messages.add({"role": "ai", "text": "Error: $e"});

        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SafeSphere AI"),

        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                speakerEnabled = !speakerEnabled;
              });
            },
            icon: Icon(speakerEnabled ? Icons.volume_up : Icons.volume_off),
          ),

          IconButton(
            onPressed: () async {
              bool? result = await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Clear Chat"),
                    content: const Text(
                      "Are you sure you want to delete all messages?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text("Cancel"),
                      ),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text("Delete"),
                      ),
                    ],
                  );
                },
              );

              if (result == true) {
                setState(() {
                  messages.clear();
                });
              }
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                bool isUser = messages[index]["role"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      messages[index]["text"]!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(),
            ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Ask SafeSphere AI...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send),
                ),

                IconButton(
                  onPressed: () async {
                    if (isListening) {
                      await stopListening();
                    } else {
                      await startListening();
                    }
                  },
                  icon: Icon(isListening ? Icons.mic : Icons.mic_none),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
