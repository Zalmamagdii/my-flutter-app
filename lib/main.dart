import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:intl/intl.dart';

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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FarmerHomePage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
    minimumSize: const Size(250, 60), // Width = 250, Height = 60
    backgroundColor: Colors.white,     // Button background
    foregroundColor: Colors.green,     // Text color
    side: const BorderSide(
      color: Colors.green,             // Border color
      width: 2,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
                child: const Text("Start", style: TextStyle(fontSize: 32) , color:Colors.green),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FarmerHomePage extends StatefulWidget {
  const FarmerHomePage({super.key});

  @override
  State<FarmerHomePage> createState() => _FarmerHomePageState();
}

class _FarmerHomePageState extends State<FarmerHomePage> {
  final FlutterBlueClassic bluetooth = FlutterBlueClassic();

  BluetoothConnection? connection;

  
  DateTime currentTime = DateTime.now();
  Timer? timer;

  String soilTemp  = "--";
  String soilMoist = "--";
  String airTemp   = "--";
  String humidity  = "--";
  String rawDebug  = "No data yet";

  String buffer = "";
  bool isConnected = false;
  bool isConnecting = false;

  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    setState(() {
      currentTime = DateTime.now();
    });
  });

  }

  Future<void> connectBluetooth() async {
  if (isConnecting) return;

  setState(() => isConnecting = true);

  try {
    connection?.dispose();
    connection = null;

    connection = await bluetooth.connect("98:D3:11:FC:DA:6B");

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => rawDebug = "connection: ${connection != null} | input: ${connection?.input != null}");
    

    setState(() {
      isConnected  = true;
      isConnecting = false;
      rawDebug     = "Connected! Waiting...";
    });

    // ✅ Use onData callback instead of .listen()
    connection?.input?.asBroadcastStream().listen(
      (data) {
        String incoming = String.fromCharCodes(data is List<int> ? data : data.toList());

        setState(() => rawDebug = "GOT: $incoming");

        buffer += incoming;

        List<String> packets = buffer.split('\n');

        for (int i = 0; i < packets.length - 1; i++) {
          String line = packets[i].replaceAll('\r', '').trim();

          if (line.isEmpty) continue;

          if (line.startsWith("Sending:")) {
            line = line.replaceFirst("Sending:", "").trim();
          }

          List<String> values = line.split(',');

          if (values.length >= 4) {
            setState(() {
              soilTemp  = values[0].trim();
              soilMoist = values[1].trim();
              airTemp   = values[2].trim();
              humidity  = values[3].trim();
              rawDebug  = "✅ $line";
            });
          }
        }

        buffer = packets.last;
      },

      onDone: () => setState(() {
        isConnected = false;
        rawDebug = "Stream closed";
      }),

      onError: (e) => setState(() {
        isConnected = false;
        rawDebug = "Stream error: $e";
      }),

      cancelOnError: false,
    );

  } catch (e) {
    setState(() {
      isConnected  = false;
      isConnecting = false;
      rawDebug     = "Failed: $e";
    });
  }
}

  @override
  void dispose() {
    timer?.cancel();
    connection?.dispose();
    super.dispose();
  }

  double getSoilTempProgress() {
  double temp = double.tryParse(soilTemp) ?? 0;
  return (temp / 50).clamp(0.0, 1.0);
}

String getSoilTempStatus() {
  double temp = double.tryParse(soilTemp) ?? 0;

  if (temp < 15) return "Cold";
  if (temp < 30) return "Moderate";
  return "Hot";
}

double getSoilMoistureProgress() {
  double moist = double.tryParse(soilMoist) ?? 0;
  return (moist / 100).clamp(0.0, 1.0);
}

String getSoilMoistureStatus() {
  double moist = double.tryParse(soilMoist) ?? 0;

  if (moist < 30) return "Dry";
  if (moist < 70) return "Normal";
  return "Wet";
}

double getAirTempProgress() {
  double temp = double.tryParse(airTemp) ?? 0;
  return (temp / 50).clamp(0.0, 1.0);
}

String getAirTempStatus() {
  double temp = double.tryParse(airTemp) ?? 0;

  if (temp < 20) return "Cool";
  if (temp < 35) return "Warm";
  return "Hot";
}

double getHumidityProgress() {
  double hum = double.tryParse(humidity) ?? 0;
  return (hum / 100).clamp(0.0, 1.0);
}

String getHumidityStatus() {
  double hum = double.tryParse(humidity) ?? 0;

  if (hum < 40) return "Low";
  if (hum < 70) return "Medium";
  return "High";
}

List<FoodItem> getSuggestedCrops() {
  double temp = double.tryParse(airTemp) ?? 0;
  double hum = double.tryParse(humidity) ?? 0;

  if (temp > 30 && hum < 50) {
    return const [
      FoodItem("🫒", "Olive"),
      FoodItem("🍇", "Grapes"),
      FoodItem("🌽", "Corn"),
    ];
  }

  if (temp > 25 && hum > 70) {
    return const [
      FoodItem("🌾", "Rice"),
      FoodItem("🍅", "Tomato"),
      FoodItem("🥔", "Potato"),
    ];
  }

  if (temp >= 20 && temp <= 30) {
    return const [
      FoodItem("🍅", "Tomato"),
      FoodItem("🌽", "Corn"),
      FoodItem("🍇", "Grapes"),
    ];
  }

  return const [
    FoodItem("🥔", "Potato"),
    FoodItem("🍅", "Tomato"),
  ];
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEDEDE7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text(
      "Hello, Farmers",
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    ),
    const SizedBox(height: 5),

    const Text(
      "Live Sensor Monitoring",
      style: TextStyle(
        color: Colors.white70,
        fontSize: 16,
      ),
    ),

    const SizedBox(height: 8),

    Text(
      DateFormat('EEEE, dd MMM yyyy').format(currentTime),
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
    ),

    Text(
      DateFormat('hh:mm:ss a').format(currentTime),
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
    ),
  ],
),

                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.bluetooth,
                                color: isConnected ? Colors.blue : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: isConnecting ? null : connectBluetooth,
                              child: Text(
                                isConnecting ? "Connecting..." :
                                isConnected  ? "Connected"     : "Connect HC-05",
                              ),
                            ),
                            const SizedBox(height: 5),
                            // DEBUG TEXT
                            Text(
                              rawDebug,
                              style: const TextStyle(color: Colors.red, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        children: [

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.location_on_outlined, color: Colors.grey),
                                  SizedBox(width: 5),
                                  Text("Egypt, Aswan",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.cloud, size: 45, color: Colors.lightBlueAccent),
                                  const SizedBox(width: 10),
                                  Text("$airTemp°C",
                                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              WeatherItem(icon: Icons.thermostat,        value: "$soilTemp°C", title: "Soil temp"),
                              WeatherItem(icon: Icons.opacity,           value: soilMoist,     title: "Soil moist"),
                              WeatherItem(icon: Icons.air,               value: "$airTemp°C",  title: "Air temp"),
                              WeatherItem(icon: Icons.water_drop_outlined, value: "$humidity%", title: "Humidity"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text("Measures Summary",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        MeasureCard(
  title: "Soil temp",
  value: "$soilTemp°C",
  status: getSoilTempStatus(),
  color: Colors.green,
  progress: getSoilTempProgress(),
),
                        MeasureCard(
  title: "Soil moist",
  value: "$soilMoist%",
  status: getSoilMoistureStatus(),
  color: Colors.blue,
  progress: getSoilMoistureProgress(),
),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        MeasureCard(
  title: "Air temp",
  value: "$airTemp°C",
  status: getAirTempStatus(),
  color: Colors.orange,
  progress: getAirTempProgress(),
),
                        MeasureCard(
  title: "Humidity",
  value: "$humidity%",
  status: getHumidityStatus(),
  color: Colors.red,
  progress: getHumidityProgress(),
),
                      ],
                    ),
                    const SizedBox(height: 30),

const Text(
  "Suggested Crops for Cultivation",
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 20),

SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: getSuggestedCrops(),
  ),
),

const SizedBox(height: 30),

const Text(
  "My Fields",
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 20),

Container(
  height: 180,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(25),
    image: const DecorationImage(
      image: NetworkImage(
        "https://images.unsplash.com/photo-1500937386664-56d1dfef3854",
      ),
      fit: BoxFit.cover,
    ),
  ),
),

const SizedBox(height: 100),
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

class WeatherItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;

  const WeatherItem({super.key, required this.icon, required this.value, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 55,
                height: 55,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
class FoodItem extends StatelessWidget {
  final String emoji;
  final String name;

  const FoodItem(this.emoji, this.name, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}