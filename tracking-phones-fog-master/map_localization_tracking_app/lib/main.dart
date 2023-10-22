import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController phoneNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: phoneNumberController,
              decoration: InputDecoration(
                labelText: 'Enter your phone number',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final phoneNumber = phoneNumberController.text;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyMapPage(phoneNumber: phoneNumber),
                  ),
                );
              },
              child: Text('Login and Start Map'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyMapPage extends StatefulWidget {
  final String phoneNumber;

  MyMapPage({required this.phoneNumber});

  @override
  _MyMapPageState createState() => _MyMapPageState();
}

class _MyMapPageState extends State<MyMapPage> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(34.7282712, 10.7155989);
  List<Marker> markers = [];
  String srvUrl = '';
  late Timer markerRemovalTimer;

  @override
  void initState() {
    super.initState();

    markerRemovalTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      removeMarkers();
    });

    _trackMe();
  }

  void removeMarkers() {
    setState(() {
      markers.clear();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  double randomHue() {
    final random = Random();
    return random.nextDouble() * 360.0;
  }

  Future<String> _getIPAddress() async {
    final response = await http.get(Uri.parse('https://api.ipify.org?format=json'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['ip'];
    } else {
      return 'Unknown';
    }
  }

  Future<void> _publishLocation(double latitude, double longitude, String phoneNumber) async {
    try {
      final payload = {
        'id': phoneNumber, // Use the phone number as the ID
        'content': {'latitude': latitude, 'longitude': longitude}
      };
      String message = json.encode(payload);

      final response = await http.post(
        Uri.parse(srvUrl),
        headers: {'Content-Type': 'application/json'},
        body: message,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        for (var item in responseData) {
          var id = item['id'];
          var lat = item['content']['latitude'];
          var long = item['content']['longitude'];

          setState(() {
            markers.add(Marker(
              markerId: MarkerId(id),
              position: LatLng(lat, long),
              infoWindow: InfoWindow(
                title: '$lat$long',
                snippet: 'Lat: $lat, Lng: $long',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(randomHue()),
            ));
          });
        }
      } else {
        print('Failed to send request. Status code: ${response.statusCode}');
        srvUrl=await getUrl();
      }
    } catch (e) {
      print('Error sending request: $e');
    }
  }
  Future<String> getUrl() async {
    List<String> servers = [
      'http://10.25.14.172:5000/position',
      'http://10.26.13.94:5000/position',
      'http://10.25.13.25:5000/position'
    ];

    // Generate a random index to select a server
    final random = Random();
    final randomIndex = random.nextInt(servers.length);

    // Return the randomly selected server URL
    return servers[randomIndex];
  }

  Future<void> _trackMe() async {
    final String ipAddress = await _getIPAddress();
    //srvUrl = 'http://10.26.13.94:5000/position';
  srvUrl = await getUrl();
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print("Latitude: ${position.latitude}");
      print("Longitude: ${position.longitude}");
      await _publishLocation(position.latitude, position.longitude, widget.phoneNumber);
    });
  }

  @override
  void dispose() {
    super.dispose();
    markerRemovalTimer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maps Localization Tracking For Phones'),
        backgroundColor: Colors.green[700],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 13.0,
        ),
        markers: Set<Marker>.from(markers),
      ),
    );
  }
}
