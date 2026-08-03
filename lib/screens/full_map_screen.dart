import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

class FullMapScreen extends StatefulWidget {
  final LatLng currentPosition;
  final LatLng? destinationPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final double distance;
  final double eta;
  final double safetyScore;

  const FullMapScreen({
    super.key,
    required this.currentPosition,
    required this.destinationPosition,
    required this.markers,
    required this.polylines,
    required this.distance,
    required this.eta,
    required this.safetyScore,
  });

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  GoogleMapController? mapController;
  BitmapDescriptor? navigationIcon;
  bool isNavigating = false;
  bool destinationReached = false;
  double remainingDistance = 0;
  double remainingETA = 0;

  StreamSubscription<Position>? positionStream;

  Set<Marker> mapMarkers = {};
  @override
  void initState() {
    super.initState();

    mapMarkers = Set<Marker>.from(widget.markers);
    remainingDistance = widget.distance;
    remainingETA = widget.eta;
    loadNavigationIcon();
  }

  Future<void> loadNavigationIcon() async {
    navigationIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(70, 70)),
      "assets/images/navigation_arrow.png",
    );
  }

  Marker? liveMarker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Navigation"),
        backgroundColor: Colors.blue,
      ),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.currentPosition,
              zoom: 16,
            ),
            onMapCreated: (controller) async {
              mapController = controller;

              if (widget.destinationPosition != null) {
                await Future.delayed(const Duration(milliseconds: 300));

                LatLngBounds bounds = LatLngBounds(
                  southwest: LatLng(
                    min(
                      widget.currentPosition.latitude,
                      widget.destinationPosition!.latitude,
                    ),
                    min(
                      widget.currentPosition.longitude,
                      widget.destinationPosition!.longitude,
                    ),
                  ),
                  northeast: LatLng(
                    max(
                      widget.currentPosition.latitude,
                      widget.destinationPosition!.latitude,
                    ),
                    max(
                      widget.currentPosition.longitude,
                      widget.destinationPosition!.longitude,
                    ),
                  ),
                );

                mapController!.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 100),
                );
              }
            },

            myLocationEnabled: true,
            myLocationButtonEnabled: true,

            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,

            markers: mapMarkers,
            polylines: widget.polylines,
          ),

          Positioned(
            left: 15,
            right: 15,
            bottom: 20,
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Route Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Distance : ${remainingDistance.toStringAsFixed(2)} km",
                    ),

                    Text("ETA : ${remainingETA.toStringAsFixed(0)} min"),

                    Text(
                      "Safety Score : ${widget.safetyScore.toStringAsFixed(0)}%",
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          startNavigation();
                        },
                        icon: const Icon(Icons.navigation),
                        label: const Text("Start Navigation"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void startNavigation() {
    if (widget.destinationPosition == null) {
      return;
    }

    isNavigating = false;

    positionStream?.cancel();

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      updateNavigation(position);
    });
  }

  void updateNavigation(Position position) {
    LatLng current = LatLng(position.latitude, position.longitude);
    if (!destinationReached && widget.destinationPosition != null) {
      double distance = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        widget.destinationPosition!.latitude,
        widget.destinationPosition!.longitude,
      );

      remainingDistance = distance / 1000;
      remainingETA = (remainingDistance / 40) * 60;

      if (distance < 20) {
        destinationReached = true;

        positionStream?.cancel();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("🎉 Destination Reached")));
      }
    }

    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: current, zoom: 19, bearing: 0, tilt: 45),
      ),
    );

    setState(() {
      mapMarkers.removeWhere((marker) => marker.markerId.value == "live");

      mapMarkers.add(
        Marker(
          markerId: const MarkerId("live"),
          position: current,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }
}
