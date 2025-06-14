import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/home_address.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';

class AddAddressScreen extends StatefulWidget {
  final Student student;
  final HomeAddress? address;

  const AddAddressScreen({
    super.key,
    required this.student,
    this.address,
  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _mapUrlController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  final _nearbyPlacesController = TextEditingController();
  
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  
  HomeType _selectedHomeType = HomeType.ownedByParents;
  double? _latitude;
  double? _longitude;
  List<String> _nearbyPlaces = [];
  bool _isLoading = false;
  bool _isParsingUrl = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _loadAddressData();
    }
  }

  void _loadAddressData() {
    final address = widget.address!;
    _addressController.text = address.address;
    _selectedHomeType = address.homeType;
    _latitude = address.latitude;
    _longitude = address.longitude;
    _nearbyPlaces = List.from(address.nearbyPlaces);
    _additionalInfoController.text = address.additionalInfo ?? '';
    _nearbyPlacesController.text = _nearbyPlaces.join(', ');
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mapUrlController.dispose();
    _additionalInfoController.dispose();
    _nearbyPlacesController.dispose();
    super.dispose();
  }

  Future<void> _parseMapUrl() async {
    final url = _mapUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาใส่ URL ของ Google Maps')),
      );
      return;
    }

    setState(() {
      _isParsingUrl = true;
    });

    try {
      final locationData = _locationService.parseSharedMapUrl(url);
      
      if (locationData != null) {
        if (locationData.containsKey('latitude') && locationData.containsKey('longitude')) {
          _latitude = locationData['latitude'];
          _longitude = locationData['longitude'];
          
          // Get address from coordinates
          final address = await _locationService.getAddressFromCoordinates(_latitude!, _longitude!);
          _addressController.text = address;
          
          // Get nearby places
          final nearbyPlaces = await _locationService.getNearbyPlaces(_latitude!, _longitude!);
          _nearbyPlaces = nearbyPlaces.map((place) => place['name'] as String).take(5).toList();
          _nearbyPlacesController.text = _nearbyPlaces.join(', ');
          
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('นำเข้าข้อมูลจาก Google Maps เรียบร้อยแล้ว')),
          );
        } else if (locationData.containsKey('place_id')) {
          final placeDetails = await _locationService.getPlaceDetails(locationData['place_id']);
          if (placeDetails != null) {
            final geometry = placeDetails['geometry']['location'];
            _latitude = geometry['lat'];
            _longitude = geometry['lng'];
            _addressController.text = placeDetails['formatted_address'] ?? '';
            
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('นำเข้าข้อมูลจาก Place ID เรียบร้อยแล้ว')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถแยกข้อมูลจาก URL ได้ กรุณาตรวจสอบ URL')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        _isParsingUrl = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาอนุญาตการเข้าถึงตำแหน่ง')),
        );
        return;
      }

      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        
        final address = await _locationService.getAddressFromCoordinates(_latitude!, _longitude!);
        _addressController.text = address;
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ได้ตำแหน่งปัจจุบันแล้ว')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการดึงตำแหน่ง: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุตำแหน่งที่อยู่')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final nearbyPlacesText = _nearbyPlacesController.text.trim();
      final nearbyPlacesList = nearbyPlacesText.isNotEmpty 
          ? nearbyPlacesText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
          : <String>[];

      final homeAddress = HomeAddress(
        id: widget.address?.id,
        studentId: widget.student.id!,
        address: _addressController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        homeType: _selectedHomeType,
        additionalInfo: _additionalInfoController.text.trim().isEmpty 
            ? null 
            : _additionalInfoController.text.trim(),
        nearbyPlaces: nearbyPlacesList,
        createdAt: widget.address?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.address == null) {
        await _databaseService.insertHomeAddress(homeAddress);
        // ignore: use_build_context_synchronously
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกที่อยู่เรียบร้อยแล้ว')),
        );
      } else {
        await _databaseService.updateHomeAddress(homeAddress);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตที่อยู่เรียบร้อยแล้ว')),
        );
      }

      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
    } catch (e) {
      // ignore: use_build_context_synchronously
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'เพิ่มที่อยู่' : 'แก้ไขที่อยู่'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveAddress,
              child: const Text('บันทึก'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.student.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),                            Text(
                              'เลขที่: ${widget.student.studentId}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Map URL Import Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'นำเข้าจาก Google Maps',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'วาง URL ที่แชร์จาก Google Maps หรือ Facebook/Line',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _mapUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL ของแผนที่',
                          hintText: 'https://maps.google.com/...',
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isParsingUrl ? null : _parseMapUrl,
                              icon: _isParsingUrl
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.download),
                              label: Text(_isParsingUrl ? 'กำลังประมวลผล...' : 'นำเข้าข้อมูล'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _getCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('ตำแหน่งปัจจุบัน'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Address Form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ข้อมูลที่อยู่',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Home Type Selection
                      Text(
                        'ประเภทที่อยู่',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      
                      DropdownButtonFormField<HomeType>(
                        value: _selectedHomeType,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.home_work),
                          border: OutlineInputBorder(),
                        ),
                        items: HomeType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type.displayName,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedHomeType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Address Field
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'ที่อยู่',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'กรุณากรอกที่อยู่';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Coordinates Display
                      if (_latitude != null && _longitude != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.gps_fixed,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'พิกัด: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Nearby Places
                      TextFormField(
                        controller: _nearbyPlacesController,
                        decoration: const InputDecoration(
                          labelText: 'สถานที่ใกล้เคียง',
                          hintText: 'เช่น 7-Eleven, โรงเรียน, วัด (คั่นด้วยจุลภาค)',
                          prefixIcon: Icon(Icons.place),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      
                      // Additional Info
                      TextFormField(
                        controller: _additionalInfoController,
                        decoration: const InputDecoration(
                          labelText: 'ข้อมูลเพิ่มเติม',
                          hintText: 'หมายเหตุหรือข้อมูลเพิ่มเติม',
                          prefixIcon: Icon(Icons.note),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.address == null ? 'บันทึกที่อยู่' : 'อัปเดตที่อยู่',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
