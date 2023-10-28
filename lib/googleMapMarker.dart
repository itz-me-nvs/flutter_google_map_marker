import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AfterLayoutMixin {
  late GoogleMapController mapController;
  List<Marker> customMarkers = [];
  BitmapDescriptor customMarker = BitmapDescriptor.defaultMarker;
  Color markerColor = Colors.red;
  List<GlobalKey> globalKeys = [];
  GlobalKey globalKey = GlobalKey();
  final LatLng initialPosition =
      const LatLng(13.192594280276914, 80.30864386287254);

  Future<BitmapDescriptor> convertWidgetToBitmap(GlobalKey markerKey) async {
    await SchedulerBinding.instance.endOfFrame; // Wait for the end of the frame
    RenderRepaintBoundary boundary =
        markerKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    ui.Image image =
        await boundary.toImage(pixelRatio: 3.0); // Adjust pixelRatio as needed
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List uint8List = byteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(uint8List);
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _getBitmaps(context).then((bitmaps) {
      setState(() {
        bitmaps.asMap().forEach((i, bmp) {
          customMarkers.add(Marker(
            markerId: MarkerId(i.toString()),
            position: locations[i].coordinates,
            icon: bmp,
          ));
          customMarker = bmp;
        });
      });
    });
  }

  Future<List<BitmapDescriptor>> _getBitmaps(BuildContext context) async {
    var futures = globalKeys.map((key) => convertWidgetToBitmap(key));
    return Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Google Maps Marker'),
        ),
        body: Stack(
          children: <Widget>[
            GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialPosition, // Set the initial map location
                  zoom: 12.0, // Set the initial zoom level
                ),
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                },
                myLocationEnabled: true,
                markers: customMarkers.toSet()),
            Transform.translate(
              offset: Offset(MediaQuery.of(context).size.width, 0),
              child: Material(
                type: MaterialType.transparency,
                child: Stack(
                    children: markerWidgets().map((e) {
                  final markerKey = GlobalKey();
                  setState(() {
                    globalKeys.add(markerKey);
                  });
                  return RepaintBoundary(
                    key: markerKey,
                    child: MapMarker(e.name),
                  );
                }).toList()),
              ),
            ),
          ],
        ));
  }
}

/// AfterLayoutMixin
mixin AfterLayoutMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => afterFirstLayout(context));
  }

  void afterFirstLayout(BuildContext context);
}

class CustomClipPath extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width / 3, 0.0);
    path.lineTo(size.width / 2, size.height / 3);
    path.lineTo(size.width - size.width / 3, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class Location {
  final LatLng coordinates;
  final String name;
  Location(this.coordinates, this.name);
}

List<Location> locations = [
  Location(const LatLng(13.192594280276914, 80.30864386287300), "McDonald's"),
  Location(const LatLng(13.192594280276914, 79.30864386287300), "KFC"),
  Location(const LatLng(13.192594280276914, 78.30864386287300), "Subway"),
  Location(const LatLng(13.192594280276914, 77.30864386287300), "Starbucks")
];
List<MapMarker> markerWidgets() {
  return locations.map((l) => MapMarker(l.name)).toList();
}

class MapMarker extends StatelessWidget {
  final String name;
  const MapMarker(this.name, {super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 40.0,
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.white,
                ),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14))),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Container(
              height: 10.0,
              decoration: BoxDecoration(
                  color: Colors.green,
                  border: Border.all(
                    color: Colors.green,
                  ),
                  borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14)))),
          ClipPath(
            clipper: CustomClipPath(),
            child: Container(
              height: 36.0,
              color: Colors.green,
            ),
          )
        ],
      ),
    );
  }
}
