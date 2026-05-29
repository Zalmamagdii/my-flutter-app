import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic_serial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const StartPage(),
    );
  }
}

// START PAGE
class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              "lib/assets/start.png",
              fit: BoxFit.cover,
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xff72C25B),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 70,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                    side: const BorderSide(
                      color: Color(0xff4E9A39),
                      width: 4,
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const FarmerHomePage(),
                    ),
                  );
                },
                child: const Text(
                  "Start",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// HOME PAGE
class FarmerHomePage extends StatefulWidget {
  const FarmerHomePage({super.key});

  @override
  State<FarmerHomePage> createState() =>
      _FarmerHomePageState();
}

class _FarmerHomePageState
    extends State<FarmerHomePage> {

  FlutterBluetoothClassicSerial bluetooth = FlutterBluetoothClassicSerial();

  String soilTemp = "--";
  String soilMoist = "--";
  String airTemp = "--";
  String humidity = "--";

  @override
  void initState() {
    super.initState();
    connectBluetooth();
  }

  Future<void> connectBluetooth() async {
  try {

    bool enabled =
        await bluetooth.isBluetoothEnabled() ?? false;

    if (!enabled) {
      await bluetooth.requestBluetoothEnabled();
    }

    await bluetooth.connect(
        "98:D3:11:FC:DA:6B");

    print("Connected");

    bluetooth.onDeviceDataReceived().listen((event) {

      String received =
          utf8.decode(event).trim();

      print(received);

      List<String> values =
          received.split(',');

      if (values.length == 4) {
        setState(() {
          soilTemp = values[0];
          soilMoist = values[1];
          airTemp = values[2];
          humidity = values[3];
        });
      }
    });

  } catch (e) {
    print(e);
  }
}

  @override
  void dispose() {
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xffEDEDE7),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // TOP SECTION
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xff6B8500),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),

                child: Column(
                  children: [

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [

                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: const [

                            Text(
                              "Hello, Farmers",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              "Live Sensor Monitoring",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        Container(
                          padding:
                              const EdgeInsets.all(12),
                          decoration:
                              const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bluetooth,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // WEATHER CARD
                    Container(
                      padding:
                          const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(30),
                      ),

                      child: Column(
                        children: [

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [

                              Row(
                                children: const [

                                  Icon(
                                    Icons
                                        .location_on_outlined,
                                    color: Colors.grey,
                                  ),

                                  SizedBox(width: 5),

                                  Text(
                                    "Egypt, Aswan",
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              Row(
                                children: [

                                  const Icon(
                                    Icons.cloud,
                                    size: 45,
                                    color:
                                        Colors.lightBlueAccent,
                                  ),

                                  const SizedBox(
                                      width: 10),

                                  Text(
                                    "$airTemp°C",
                                    style:
                                        const TextStyle(
                                      fontSize: 30,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceAround,
                            children: [

                              WeatherItem(
                                icon:
                                    Icons.thermostat,
                                value:
                                    "$soilTemp°C",
                                title:
                                    "Soil temp",
                              ),

                              WeatherItem(
                                icon: Icons.opacity,
                                value:
                                    soilMoist,
                                title:
                                    "Soil moist",
                              ),

                              WeatherItem(
                                icon: Icons.air,
                                value:
                                    "$airTemp°C",
                                title:
                                    "Air temp",
                              ),

                              WeatherItem(
                                icon: Icons
                                    .water_drop_outlined,
                                value:
                                    "$humidity%",
                                title:
                                    "Humidity",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // MEASURES
              Padding(
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Measures Summary",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceAround,
                      children: [

                        MeasureCard(
                          title: "Soil temp",
                          value:
                              "$soilTemp°C",
                          status: "Live",
                          color: Colors.green,
                          progress: 0.6,
                        ),

                        MeasureCard(
                          title:
                              "Soil moist",
                          value:
                              soilMoist,
                          status: "Live",
                          color: Colors.blue,
                          progress: 0.7,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceAround,
                      children: [

                        MeasureCard(
                          title:
                              "Air temp",
                          value:
                              "$airTemp°C",
                          status: "Live",
                          color:
                              Colors.orange,
                          progress: 0.4,
                        ),

                        MeasureCard(
                          title:
                              "Humidity",
                          value:
                              "$humidity%",
                          status: "Live",
                          color: Colors.red,
                          progress: 0.3,
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
    );
  }
}

// WEATHER ITEM
class WeatherItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;

  const WeatherItem({
    super.key,
    required this.icon,
    required this.value,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// MEASURE CARD
class MeasureCard extends StatelessWidget {

  final String title;
  final String value;
  final String status;
  final Color color;
  final double progress;

  const MeasureCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        children: [

          Text(
            title,
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Stack(
            alignment:
                Alignment.center,
            children: [

              SizedBox(
                width: 55,
                height: 55,
                child:
                    CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor:
                      Colors.grey.shade300,
                  valueColor:
                      AlwaysStoppedAnimation(
                          color),
                ),
              ),

              Text(
                value,
                style:
                    const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}