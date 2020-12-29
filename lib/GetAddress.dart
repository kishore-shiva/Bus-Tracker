import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

class GetAddress {
  List addresses;
  Future<List> get_address(double lat, double long) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
    int len = placemarks.length;
    addresses = new List(len);
    for (int i = 0; i < len; i++) {
      print('THIS IS A ' + placemarks[i].thoroughfare + ' ---------------');
      addresses[i] = placemarks[i].thoroughfare;
    }
    print('ADDRESSES IS --------------' + addresses.toString() + '-----------');

    return addresses;
  }
}
