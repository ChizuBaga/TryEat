// lib/locator.dart
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chikankan/Controller/mnb_classifier.dart';
import 'package:huawei_location/huawei_location.dart';
import 'package:chikankan/Controller/location_controller.dart';

// Create a global instance of GetIt
final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => FirebaseFirestore.instance);
  locator.registerLazySingleton(() => NaiveBayesClassifier());
  locator.registerLazySingleton(() => FusedLocationProviderClient());
  locator.registerLazySingleton(() => LocationController());
}