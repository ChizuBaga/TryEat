import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class NaiveBayesClassifier {
  late Map<String, int> _vocabulary;
  late List<double> _classLogPrior;
  late List<List<double>> _featureLogProb;
  late List<int> _classes;
  bool _isModelLoaded = false;
  static final NaiveBayesClassifier _instance = NaiveBayesClassifier._internal();
  

  factory NaiveBayesClassifier() {
    return _instance;
  }


  NaiveBayesClassifier._internal();

  
  Future<void> loadModel() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/naive_bayes_model.json');
      final Map<String, dynamic> modelData = json.decode(jsonString);

      final List<dynamic> vocabList = modelData['vocabulary'];
      _vocabulary = { for (int i = 0; i < vocabList.length; i++) vocabList[i] as String : i };

      _classLogPrior = (modelData['class_log_prior'] as List).map((e) => e as double).toList();
      
      _featureLogProb = (modelData['feature_log_prob'] as List)
          .map((row) => (row as List).map((e) => e as double).toList())
          .toList();

      _classes = (modelData['classes'] as List).map((e) => e as int).toList();
      _isModelLoaded = true;
      print("Model loaded successfully!");

    } catch (e) {
      print("Error loading model: $e");
    }
  }

  int predict(String text) {
    if (!_isModelLoaded) {
      throw Exception("Model is not loaded. Please call loadModel() first.");
    }
    
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    List<double> scores = List.from(_classLogPrior);

    for (final word in words) {
      if (_vocabulary.containsKey(word)) {
        final int wordIndex = _vocabulary[word]!;
        for (int i = 0; i < _classes.length; i++) {
          scores[i] += _featureLogProb[i][wordIndex];
        }
      }
    }

    double maxScore = -double.infinity;
    int bestClassIndex = -1;
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        bestClassIndex = i;
      }
    }
    return _classes[bestClassIndex];
  }
}