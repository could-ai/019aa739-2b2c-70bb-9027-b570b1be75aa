import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'ml/dataset.dart';
import 'ml/logistic_regression.dart';

void main() {
  runApp(const TennisApp());
}

class TennisApp extends StatelessWidget {
  const TennisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tennis Predictor',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Model
  final LogisticRegression _model = LogisticRegression();
  bool _isTrained = false;
  double? _lastPredictionProb;
  bool? _lastPredictionResult;

  // Form Selection
  String _selectedOutlook = TennisDataset.outlooks[0];
  String _selectedTemp = TennisDataset.temps[0];
  String _selectedHumidity = TennisDataset.humidities[0];
  String _selectedWind = TennisDataset.winds[0];

  // Data
  List<Map<String, String>> _data = List.from(TennisDataset.defaultData);

  @override
  void initState() {
    super.initState();
    _trainModel(); // Auto-train on startup
  }

  void _trainModel() {
    final prepared = TennisDataset.prepareTrainingData(_data);
    _model.train(prepared['X'], prepared['y']);
    setState(() {
      _isTrained = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Model trained successfully!')),
    );
  }

  Future<void> _importExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, // Important for web to get bytes
      );

      if (result != null) {
        Uint8List? fileBytes = result.files.first.bytes;
        if (fileBytes != null) {
          List<Map<String, String>> newData = await TennisDataset.parseExcel(fileBytes);
          
          if (newData.isNotEmpty) {
            setState(() {
              _data = newData;
              _isTrained = false; // Reset training status
              _lastPredictionResult = null; // Reset prediction
            });
            _trainModel(); // Retrain with new data
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Imported ${newData.length} rows from Excel!')),
              );
            }
          } else {
             if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No valid data found in Excel. Check column names.')),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing file: $e')),
        );
      }
    }
  }

  void _predict() {
    if (!_isTrained) return;

    List<double> input = TennisDataset.encode(
      _selectedOutlook,
      _selectedTemp,
      _selectedHumidity,
      _selectedWind,
    );

    double prob = _model.predictProbability(input);
    bool result = _model.predict(input);

    setState(() {
      _lastPredictionProb = prob;
      _lastPredictionResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tennis Predictor'),
        backgroundColor: Colors.green.shade100,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header / Intro
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'This app uses Logistic Regression to predict if you can play tennis based on weather conditions. '
                  'The model is trained on the dataset below. You can import your own Excel file to retrain the model.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Prediction Form
            Text('Make a Prediction', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildDropdown('Outlook', TennisDataset.outlooks, _selectedOutlook, (val) => setState(() => _selectedOutlook = val!)),
                    _buildDropdown('Temperature', TennisDataset.temps, _selectedTemp, (val) => setState(() => _selectedTemp = val!)),
                    _buildDropdown('Humidity', TennisDataset.humidities, _selectedHumidity, (val) => setState(() => _selectedHumidity = val!)),
                    _buildDropdown('Wind', TennisDataset.winds, _selectedWind, (val) => setState(() => _selectedWind = val!)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isTrained ? _predict : null,
                        icon: const Icon(Icons.sports_tennis),
                        label: const Text('PREDICT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Result Display
            if (_lastPredictionResult != null) ...[
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  decoration: BoxDecoration(
                    color: _lastPredictionResult! ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _lastPredictionResult! ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _lastPredictionResult! ? "Yes, Play Tennis!" : "No, Don't Play.",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _lastPredictionResult! ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Confidence: ${(_lastPredictionProb! * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            // 4. Training Data Table
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Training Data (${_data.length} rows)', style: Theme.of(context).textTheme.headlineSmall),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _importExcel,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import Excel'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _trainModel,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retrain'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
                columns: const [
                  DataColumn(label: Text('Outlook', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Temp', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Humidity', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Wind', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Play?', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _data.map((row) {
                  final play = row['Play'] == 'Yes';
                  return DataRow(
                    cells: [
                      DataCell(Text(row['Outlook'] ?? '')),
                      DataCell(Text(row['Temperature'] ?? '')),
                      DataCell(Text(row['Humidity'] ?? '')),
                      DataCell(Text(row['Wind'] ?? '')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: play ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            row['Play'] ?? '',
                            style: TextStyle(
                              color: play ? Colors.green.shade800 : Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String currentValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
