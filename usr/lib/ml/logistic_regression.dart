import 'dart:math';

class LogisticRegression {
  List<double> weights = [];
  double learningRate;
  int iterations;

  LogisticRegression({this.learningRate = 0.1, this.iterations = 2000});

  double sigmoid(double z) {
    return 1 / (1 + exp(-z));
  }

  void train(List<List<double>> X, List<int> y) {
    if (X.isEmpty || X.length != y.length) return;

    int nSamples = X.length;
    int nFeatures = X[0].length;
    
    // Initialize weights with zeros (including bias if handled externally, 
    // but here we assume X includes a bias column of 1s if needed. 
    // We will add bias handling in the data prep stage usually, 
    // but let's handle it here for simplicity by assuming X is raw features 
    // and we add a bias weight and term.)
    
    // Actually, let's keep it simple: The encoder will add a bias term (1.0) to features.
    weights = List.filled(nFeatures, 0.0);

    for (int iter = 0; iter < iterations; iter++) {
      // Calculate gradients
      List<double> gradients = List.filled(nFeatures, 0.0);
      
      for (int i = 0; i < nSamples; i++) {
        double z = 0.0;
        for (int j = 0; j < nFeatures; j++) {
          z += X[i][j] * weights[j];
        }
        double predicted = sigmoid(z);
        double error = predicted - y[i];
        
        for (int j = 0; j < nFeatures; j++) {
          gradients[j] += error * X[i][j];
        }
      }

      // Update weights
      for (int j = 0; j < nFeatures; j++) {
        weights[j] -= learningRate * (gradients[j] / nSamples);
      }
    }
  }

  double predictProbability(List<double> x) {
    if (weights.isEmpty || x.length != weights.length) return 0.0;
    
    double z = 0.0;
    for (int i = 0; i < x.length; i++) {
      z += x[i] * weights[i];
    }
    return sigmoid(z);
  }

  bool predict(List<double> x, {double threshold = 0.5}) {
    return predictProbability(x) >= threshold;
  }
}
