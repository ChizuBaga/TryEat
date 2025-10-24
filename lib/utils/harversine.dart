import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:huawei_location/huawei_location.dart';
import 'dart:math';

class Harversine{
  GeoPoint geoPoint;
  double r = 6371;
  double lat;
  double lon;

  Harversine(this.lat, this.lon, {required this.geoPoint});

  Harversine getCoordinates(GeoPoint gp){
    double lat = gp.latitude;
    double lon = gp.longitude;
    return Harversine(lat, lon, geoPoint: geoPoint);
  }

  //getters
  double getLat(){
    return lat;
  }

  double getLon(){
    return lon;
  }

  double toRadian(double degree){
    return degree * (pi / 180);
  }

  double radDifferences(double rad1, double rad2){
    return rad2 - rad1;
  }

  double sinnSquare(double sinVal){
    return sinVal * sinVal;
  }

  //Calc distance of 2 points
  double calcDistance (double lat2, double lon2){
    double a = aTerm(lat2, lon2);
    return r * calcC(a);
  }
  
  //c-term calculation
  double calcC(double a){
    return 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  //a-term calculation
  double aTerm(double lat2, double lon2){
    double rad1 = toRadian(lat);
    double rad2 = toRadian(lon);
    double radDiff1 = radDifferences(rad1, rad2);
    double radDiff2 = radDifferences(toRadian(lat2), toRadian(lon2));

    double a = sinnSquare((radDiff1) / 2) + cos(rad1) * cos(rad2) * sinnSquare(radDiff2 / 2);
    return a;
  }

}