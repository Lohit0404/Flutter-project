import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class AddEditCodeScreen extends StatefulWidget {
  final DocumentSnapshot? document;

  const AddEditCodeScreen({Key? key, this.document}) : super(key: key);

  @override
  State<AddEditCodeScreen> createState() => _AddEditCodeScreenState();
}

class _AddEditCodeScreenState extends State<AddEditCodeScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedType = '';
  bool _isActive = true;

  final TextEditingController _shortDescController = TextEditingController();
  final TextEditingController _longDescController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _metersController = TextEditingController();

  final List<String> _typeOptions = [
    'Sick Leave',
    'Casual Leave',
    'Maternity',
    'Comp off',
    'Location',
  ];

  final Map<String, Map<String, String>> _defaultDescriptions = {
    'Sick Leave': {'short': 'SL', 'long': 'Sick Leave for health reasons'},
    'Casual Leave': {'short': 'CL', 'long': 'Casual leave for personal matters'},
    'Maternity': {'short': 'ML', 'long': 'Maternity Leave for childbirth'},
    'Comp off': {'short': 'CO', 'long': 'Compensatory Off for extra work'},
  };

  @override
  void initState() {
    super.initState();
    if (widget.document != null) {
      final data = widget.document!.data() as Map<String, dynamic>;
      _selectedType = data['type'] ?? '';
      _shortDescController.text = data['shortDescription'] ?? '';
      _longDescController.text = data['longDescription'] ?? '';
      _latitudeController.text = data['latitude']?.toString() ?? '';
      _longitudeController.text = data['longitude']?.toString() ?? '';
      _metersController.text = data['meters']?.toString() ?? '';
      _isActive = data['active'] ?? true;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });
    } catch (e) {
      print('Location error: $e');
    }
  }

  Future<void> _autoFillFromType(String type) async {
    if (widget.document == null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('code_master')
            .where('type', isEqualTo: type)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first.data();
          setState(() {
            _shortDescController.text = doc['shortDescription'] ?? '';
            _longDescController.text = doc['longDescription'] ?? '';
          });
        } else if (_defaultDescriptions.containsKey(type)) {
          setState(() {
            _shortDescController.text =
                _defaultDescriptions[type]!['short'] ?? '';
            _longDescController.text =
                _defaultDescriptions[type]!['long'] ?? '';
          });
        } else {
          setState(() {
            _shortDescController.clear();
            _longDescController.clear();
          });
        }
      } catch (e) {
        print('Auto-fill error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document != null ? 'Edit Code' : 'Add Code'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _typeOptions.contains(_selectedType) ? _selectedType : null,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: _typeOptions
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                    _autoFillFromType(value);
                  }
                },
                validator: (value) =>
                value == null || value.isEmpty ? 'Please select a type' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _shortDescController,
                decoration: const InputDecoration(
                  labelText: 'Short Description',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Short description required' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _longDescController,
                decoration: const InputDecoration(
                  labelText: 'Long Description',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Long description required' : null,
              ),
              const SizedBox(height: 10),

              if (_selectedType == 'Location') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Latitude required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Longitude required' : null,
                      ),
                    ),
                    IconButton(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _metersController,
                  decoration: const InputDecoration(
                    labelText: 'Meters',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Meters required' : null,
                ),
              ],

              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final data = {
                    'type': _selectedType,
                    'shortDescription': _shortDescController.text.trim(),
                    'longDescription': _longDescController.text.trim(),
                    'active': _isActive,
                  };

                  if (_selectedType == 'Location') {
                    data['latitude'] =
                        double.tryParse(_latitudeController.text.trim()) ?? 0.0;
                    data['longitude'] =
                        double.tryParse(_longitudeController.text.trim()) ?? 0.0;
                    data['meters'] =
                        double.tryParse(_metersController.text.trim()) ?? 0.0;
                  }

                  if (widget.document != null) {
                    await FirebaseFirestore.instance
                        .collection('code_master')
                        .doc(widget.document!.id)
                        .update(data);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('code_master')
                        .add(data);
                  }

                  Navigator.pop(context);
                },
                child: Text(widget.document != null ? 'Update' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
