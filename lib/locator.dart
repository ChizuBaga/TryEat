// lib/locator.dart

import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chikankan/Controller/mnb_classifier.dart';

// Create a global instance of GetIt
final GetIt locator = GetIt.instance;

void setupLocator() {
  // Register FirebaseFirestore as a lazy singleton.
  // It will be created only when it's first requested.
  locator.registerLazySingleton(() => FirebaseFirestore.instance);
  locator.registerLazySingleton(() => NaiveBayesClassifier());
}