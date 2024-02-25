import 'dart:async';
import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Map<Permission, PermissionStatus> statuses = await [
    Permission.storage,
  ].request();
  SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensors',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0x9f4376f8),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>{
  
  List<List<dynamic>> accelerometerEvent = [
    ['acc_x','acc_y','acc_z']
  ];
  List<List<dynamic>> gyroscopeEvent = [[
    'gyro_x','gyro_y','gyro_z'
  ]];


  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  // Frequency Rate
  Duration sensorInterval = const Duration(milliseconds: 8);

  final _isHours = true;

  final StopWatchTimer _stopWatchTimer = StopWatchTimer(
    mode: StopWatchMode.countUp,
  );
  Future<void> saveCsv(List<List<dynamic>> rows, String name) async {
    String csv = const ListToCsvConverter().convert(rows);
    String dir = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOCUMENTS
    );
    print("dir $dir");
    String file = "$dir";
    File f = File(file + "/$name");
    f.writeAsString(csv);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensors'),
        elevation: 4,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<int>(
              stream: _stopWatchTimer.rawTime,
              initialData: _stopWatchTimer.rawTime.value,
              builder: (context, snap) {
                final value = snap.data!;
                final displayTime =
                StopWatchTimer.getDisplayTime(value, hours: _isHours);
                return Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        displayTime,
                        style: const TextStyle(
                            fontSize: 40,
                            fontFamily: 'Helvetica',
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: FilledButton(
                      onPressed: (){
                        _stopWatchTimer.onResetTimer();
                        _stopWatchTimer.onStartTimer();
                        sensor();
                      },
                      child: const Text(
                        'Start',
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: FilledButton(
                      onPressed:(){
                        _stopWatchTimer.onStopTimer();
                        for (final subscription in _streamSubscriptions) {
                          subscription.cancel();
                        }
                        saveCsv(accelerometerEvent,"Accelerometer.csv");
                        saveCsv(gyroscopeEvent,"Gyroscope.csv");
                        gyroscopeEvent = [[
                          'gyro_x','gyro_y','gyro_z'
                        ]];
                        accelerometerEvent = [
                          ['acc_x','acc_y','acc_z']
                        ];
                      },
                      child: const Text(
                        'Stop',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  void sensor(){
    _streamSubscriptions.add(
      accelerometerEventStream(samplingPeriod: sensorInterval).listen(
            (AccelerometerEvent event) {
          setState(() {
            accelerometerEvent.add([event.x, event.y, event.z]);
          });
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support Accelerometer Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEventStream(samplingPeriod: sensorInterval).listen(
            (GyroscopeEvent event) {
          setState(() {
            gyroscopeEvent.add([event.x, event.y, event.z]);
          });
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support Gyroscope Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
  }
}