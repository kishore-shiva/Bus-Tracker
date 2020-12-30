import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoder/geocoder.dart';
import 'package:wakelock/wakelock.dart';
import 'GetAddress.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme:
          ThemeData(primaryColor: Colors.black, highlightColor: Colors.orange),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LatLng _initialcameraposition = LatLng(20.5937, 78.9629);
  GoogleMapController _controller;
  Location _location = Location();
  BitmapDescriptor customIcon;
  final ScrollController _scrollController = new ScrollController();
  final scrollDirection = Axis.horizontal;
  final route1 = [""];
  Color notReached = Colors.red, Reached = Colors.green;
  GetAddress getGeoAddress = new GetAddress();
  var loading = true;
  final _firestore = Firestore.instance;
  String reachedLocations = "";

  List Route1 = [
    "Mookathal Street",
    "Doctor Nair Road",
    "Pantheon Road",
    "College Road",
    "Haddows Road",
    "Nungambakkam High Road"
  ];
  final colors = new List();

  List<Widget> generateRoutesUI(var routes) {
    List<Widget> RowList = [];
    for (int i = 0; i < routes.length; i++) {
      if (i == routes.length - 1) {
        RowList.add(Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                child: Text(
                  routes[i],
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                height: 15,
                width: 15,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: colors[i]),
              ),
            ],
          ),
        ));
      } else {
        RowList.add(
          Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  child: Text(
                    routes[i],
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  child: Row(
                    children: [
                      Container(
                        height: 15,
                        width: 15,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: colors[i]),
                      ),
                      Container(
                        height: 4,
                        width: 100,
                        decoration: BoxDecoration(
                            shape: BoxShape.rectangle, color: colors[i]),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return RowList;
  }

  Set<Circle> mycircles = Set.from([
    Circle(
      circleId: CircleId('1'),
      center: LatLng(0, 0),
      radius: 4000,
    )
  ]);

  void _onMapCreated(GoogleMapController _cntlr) {
    _controller = _cntlr;
    Location location = new Location();
    _location.onLocationChanged().listen((l) {
      getAddress(l.latitude, l.longitude);
      _controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(l.latitude, l.longitude), zoom: 16),
        ),
      );
    });
  }

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  void getAddress(double lat, double long) async {
    final coordinates = new Coordinates(lat, long);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = addresses.first;
    if (loading == false) {
      Fluttertoast.showToast(
          msg:
              "${first.featureName} : ${first.addressLine} : ${first.subLocality}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
    int i = 0;
    getGeoAddress.get_address(lat, long).then((value) => {
          for (int i = 0; i < Route1.length; i++)
            {
              if (value.contains(Route1[i]))
                {
                  setState(() {
                    colors[i] = Reached;
                  }),
                  if (!reachedLocations
                      .contains(new RegExp(Route1[i], caseSensitive: false)))
                    {
                      _firestore
                          .collection('Bus1 Updates')
                          .add({'reached': Route1[i]}),
                      reachedLocations += Route1[i]
                    }
                  else
                    {}
                  //Update the reached points database for the client app
                }
            }
        });
  }

  void _add(double lat, double lng, BitmapDescriptor icon) {
    var markerIdVal = "assets/bus_marker.png";
    final MarkerId markerId = MarkerId(markerIdVal);

    // creating a new MARKER
    final Marker marker = Marker(
        markerId: markerId,
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: markerIdVal, snippet: '*'),
        icon: icon);

    setState(() {
      // adding a new marker to map
      markers[markerId] = marker;
    });
  }

  void getCurrentLocation() async {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(12, 12)), 'assets/bus_marker.png')
        .then((d) {
      customIcon = d;
    });
    _location.onLocationChanged().listen((event) {
      _add(event.latitude, event.longitude, customIcon);
    });
  }

  @override
  void initState() {
    getCurrentLocation();
    _onMapCreated(_controller);
    Wakelock.enable();
    for (int i = 0; i < Route1.length; i++) {
      colors.add(notReached);
    }
    print("_____________ ON INIT EXECUTES __________________");
    Future.delayed(const Duration(milliseconds: 4000), () async {
      setState(() {
        loading = false;
      });
    });

    // Adding Data to the Firestore database
    /**_firestore.collection('Bus1').add({
      'Route1': "Mookathal Street",
      'Route2': "Doctor Nair Road",
      'Route3': "Pantheon Road",
      'Route4': "College Road",
      'Route5': "Haddows Road",
      'Route6': "Nungambakkam High Road"
    });*/

    print('------------FIREBASE ADDED BUS1 ROUTE IS : ---------------');
    updateRoutes();
  }

  void updateRoutes() async {
    final updateRoutes =
        await _firestore.collection('Bus1 Updates').getDocuments();
    for (var update in updateRoutes.documents) {
      reachedLocations += update.data()['reached'];
      colors[Route1.indexOf(update.data()['reached'])] = Reached;
    }
  }

  Future<String> scroller() async {
    _scrollController.jumpTo(100);
    Position position = await Geolocator.getCurrentPosition();
    return position.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Google maps Flutter")),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: ModalProgressHUD(
            inAsyncCall: loading,
            opacity: 0.6,
            color: Colors.black,
            progressIndicator: SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                valueColor: new AlwaysStoppedAnimation<Color>(Colors.black),
                backgroundColor: Colors.orange,
                strokeWidth: 7,
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: 0.8 * MediaQuery.of(context).size.height - 80,
                  width: MediaQuery.of(context).size.width,
                  child: GoogleMap(
                    myLocationButtonEnabled: true,
                    initialCameraPosition:
                        CameraPosition(target: _initialcameraposition),
                    mapType: MapType.normal,
                    onMapCreated: _onMapCreated,
                    myLocationEnabled: true,
                    onCameraMove: null,
                    markers: Set<Marker>.of(markers.values),
                  ),
                ),
                Container(
                    height: 0.2 * MediaQuery.of(context).size.height - 12,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.black,
                    child: Container(
                        margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: Scrollbar(
                          isAlwaysShown: true,
                          controller: _scrollController,
                          radius: Radius.circular(50),
                          thickness: 10,
                          child: Center(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: generateRoutesUI(Route1),
                              ),
                            ),
                          ),
                        ))),
              ],
            )),
      ),
    );
  }
}
