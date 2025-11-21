import 'package:excel/excel.dart';
import 'dart:typed_data';

class TennisDataset {
  // Raw data: Outlook, Temperature, Humidity, Wind, PlayTennis
  static List<Map<String, String>> defaultData = [
    {'Outlook': 'Sunny', 'Temperature': 'Hot', 'Humidity': 'High', 'Wind': 'Weak', 'Play': 'No'},
    {'Outlook': 'Sunny', 'Temperature': 'Hot', 'Humidity': 'High', 'Wind': 'Strong', 'Play': 'No'},
    {'Outlook': 'Overcast', 'Temperature': 'Hot', 'Humidity': 'High', 'Wind': 'Weak', 'Play': 'Yes'},
    {'Outlook': 'Rain', 'Temperature': 'Mild', 'Humidity': 'High', 'Wind': 'Weak', 'Play': 'Yes'},
    {'Outlook': 'Rain', 'Temperature': 'Cool', 'Humidity': 'Normal', 'Wind': 'Weak', 'Play': 'Yes'},
    {'Outlook': 'Rain', 'Temperature': 'Cool', 'Humidity': 'Normal', 'Wind': 'Strong', 'Play': 'No'},
    {'Outlook': 'Overcast', 'Temperature': 'Cool', 'Humidity': 'Normal', 'Wind': 'Strong', 'Play': 'Yes'},
    {'Outlook': 'Sunny', 'Temperature': 'Mild', 'Humidity': 'High', 'Wind': 'Weak', 'Play': 'No'},
    {'Outlook': 'Sunny', 'Temperature': 'Cool', 'Humidity': 'Normal', 'Wind': 'Weak', 'Play': 'Yes'},
    {'Outlook': 'Rain', 'Temperature': 'Mild', 'Humidity': 'Normal', 'Wind': 'Weak', 'Play': 'Yes'},
    {'Outlook': 'Sunny', 'Temperature': 'Mild', 'Humidity': 'Normal', 'Wind': 'Strong', 'Play': 'Yes'},
    {'Outlook': 'Overcast', 'Temperature': 'Mild', 'Humidity': 'High', 'Wind': 'Strong', 'Play': 'Yes'},
    {'Outlook': 'Overcast', 'Temperature': 'Hot', 'Humidity': 'Normal', 'Wind': 'Weak', 'Play': 'Yes'},
    {'Outlook': 'Rain', 'Temperature': 'Mild', 'Humidity': 'High', 'Wind': 'Strong', 'Play': 'No'},
  ];

  // Unique values for encoding
  static const List<String> outlooks = ['Sunny', 'Overcast', 'Rain'];
  static const List<String> temps = ['Hot', 'Mild', 'Cool'];
  static const List<String> humidities = ['High', 'Normal'];
  static const List<String> winds = ['Weak', 'Strong'];

  // One-Hot Encoding Helper
  // We will flatten the features into a single list of doubles
  // Structure: [Bias(1.0), Outlook_Sunny, Outlook_Overcast, Outlook_Rain, Temp_Hot, ..., Wind_Strong]
  static List<double> encode(String outlook, String temp, String humidity, String wind) {
    List<double> features = [1.0]; // Bias term

    // Outlook (3)
    features.add(outlook == 'Sunny' ? 1.0 : 0.0);
    features.add(outlook == 'Overcast' ? 1.0 : 0.0);
    features.add(outlook == 'Rain' ? 1.0 : 0.0);

    // Temperature (3)
    features.add(temp == 'Hot' ? 1.0 : 0.0);
    features.add(temp == 'Mild' ? 1.0 : 0.0);
    features.add(temp == 'Cool' ? 1.0 : 0.0);

    // Humidity (2)
    features.add(humidity == 'High' ? 1.0 : 0.0);
    features.add(humidity == 'Normal' ? 1.0 : 0.0);

    // Wind (2)
    features.add(wind == 'Weak' ? 1.0 : 0.0);
    features.add(wind == 'Strong' ? 1.0 : 0.0);

    return features;
  }

  static Map<String, dynamic> prepareTrainingData(List<Map<String, String>> rawData) {
    List<List<double>> X = [];
    List<int> y = [];

    for (var row in rawData) {
      // Ensure we handle potential missing or messy data gracefully
      String outlook = row['Outlook'] ?? 'Sunny';
      String temp = row['Temperature'] ?? 'Mild';
      String humidity = row['Humidity'] ?? 'Normal';
      String wind = row['Wind'] ?? 'Weak';
      String play = row['Play'] ?? 'No';

      X.add(encode(outlook, temp, humidity, wind));
      y.add(play == 'Yes' ? 1 : 0);
    }

    return {'X': X, 'y': y};
  }

  // Parse Excel file bytes into a list of maps
  static Future<List<Map<String, String>>> parseExcel(Uint8List bytes) async {
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, String>> newData = [];

    // Assume the first sheet contains the data
    // and the first row is the header: Outlook, Temperature, Humidity, Wind, Play
    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];
      if (sheet == null) continue;

      bool isHeader = true;
      Map<int, String> headers = {};

      for (var row in sheet.rows) {
        if (isHeader) {
          // Map column index to header name
          for (int i = 0; i < row.length; i++) {
            var cellValue = row[i]?.value?.toString().trim();
            if (cellValue != null) {
              headers[i] = cellValue;
            }
          }
          isHeader = false;
        } else {
          // Data row
          Map<String, String> rowData = {};
          bool hasData = false;
          for (int i = 0; i < row.length; i++) {
            if (headers.containsKey(i)) {
              var val = row[i]?.value?.toString().trim() ?? '';
              rowData[headers[i]!] = val;
              if (val.isNotEmpty) hasData = true;
            }
          }
          // Only add if we have valid keys and some data
          if (hasData &&
              rowData.containsKey('Outlook') &&
              rowData.containsKey('Temperature') &&
              rowData.containsKey('Humidity') &&
              rowData.containsKey('Wind') &&
              rowData.containsKey('Play')) {
            newData.add(rowData);
          }
        }
      }
      // Just process the first table/sheet
      break; 
    }
    return newData;
  }
}
