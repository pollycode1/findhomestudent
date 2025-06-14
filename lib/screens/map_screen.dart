import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/student.dart';
import '../models/home_address.dart';
import '../services/database_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final DatabaseService _databaseService = DatabaseService();
  GoogleMapController? _mapController;
  
  List<Student> _students = [];
  List<HomeAddress> _addresses = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;

  // Default location (Thailand)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(13.7563, 100.5018), // Bangkok
    zoom: 10,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final students = await _databaseService.getAllStudents();
      final allAddresses = <HomeAddress>[];
      
      for (final student in students) {
        final studentAddresses = await _databaseService.getHomeAddressesForStudent(student.id!);
        allAddresses.addAll(studentAddresses);
      }

      setState(() {
        _students = students;
        _addresses = allAddresses;
        _isLoading = false;
      });

      _createMarkers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
      );
    }
  }

  void _createMarkers() {
    final markers = <Marker>{};
    
    for (final address in _addresses) {
      final student = _students.firstWhere((s) => s.id == address.studentId);
      
      markers.add(
        Marker(
          markerId: MarkerId('address_${address.id}'),
          position: LatLng(address.latitude, address.longitude),
          infoWindow: InfoWindow(
            title: student.name,
            snippet: address.homeType.displayName,
          ),
          icon: _getMarkerIcon(address.homeType),
          onTap: () => _showAddressDetails(student, address),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });

    // Fit all markers in view
    if (_markers.isNotEmpty && _mapController != null) {
      _fitMarkersInView();
    }
  }

  BitmapDescriptor _getMarkerIcon(HomeType homeType) {
    switch (homeType) {
      case HomeType.ownedByParents:
      case HomeType.rentedByParents:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case HomeType.relativesHome:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case HomeType.guardianHome:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case HomeType.temple:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case HomeType.foundation:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case HomeType.dormitory:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case HomeType.factory:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      case HomeType.employerHome:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
    }
  }

  void _fitMarkersInView() {
    if (_markers.isEmpty) return;

    final bounds = _calculateBounds();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  LatLngBounds _calculateBounds() {
    final latitudes = _markers.map((m) => m.position.latitude);
    final longitudes = _markers.map((m) => m.position.longitude);

    return LatLngBounds(
      southwest: LatLng(
        latitudes.reduce((a, b) => a < b ? a : b),
        longitudes.reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        latitudes.reduce((a, b) => a > b ? a : b),
        longitudes.reduce((a, b) => a > b ? a : b),
      ),
    );
  }

  void _showAddressDetails(Student student, HomeAddress address) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Student Info
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            student.name.isNotEmpty ? student.name[0] : 'N',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [                              Text(
                                student.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'เลขที่: ${student.studentId}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 32),
                    
                    // Address Info
                    _buildInfoRow(Icons.home_work, 'ประเภทที่อยู่', address.homeType.displayName),
                    _buildInfoRow(Icons.location_on, 'ที่อยู่', address.address),
                    _buildInfoRow(Icons.gps_fixed, 'พิกัด', '${address.latitude.toStringAsFixed(6)}, ${address.longitude.toStringAsFixed(6)}'),
                    
                    if (address.nearbyPlaces.isNotEmpty)
                      _buildInfoRow(Icons.place, 'สถานที่ใกล้เคียง', address.nearbyPlaces.join(', ')),
                    
                    if (address.additionalInfo != null && address.additionalInfo!.isNotEmpty)
                      _buildInfoRow(Icons.note, 'ข้อมูลเพิ่มเติม', address.additionalInfo!),
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openInGoogleMaps(address),
                            icon: const Icon(Icons.map),
                            label: const Text('เปิดใน Google Maps'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _centerOnMarker(address),
                            icon: const Icon(Icons.center_focus_strong),
                            label: const Text('ไปที่ตำแหน่ง'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _openInGoogleMaps(HomeAddress address) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${address.latitude},${address.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเปิด Google Maps ได้')),
      );
    }
  }

  void _centerOnMarker(HomeAddress address) {
    Navigator.pop(context); // Close bottom sheet
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(address.latitude, address.longitude),
        16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แผนที่บ้านนักเรียน'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _showLegend,
            icon: const Icon(Icons.legend_toggle),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ยังไม่มีข้อมูลที่อยู่บ้านนักเรียน',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'เพิ่มข้อมูลนักเรียนและที่อยู่เพื่อแสดงในแผนที่',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    if (_markers.isNotEmpty) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _fitMarkersInView();
                      });
                    }
                  },
                  initialCameraPosition: _initialPosition,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                ),
      floatingActionButton: _addresses.isNotEmpty
          ? FloatingActionButton(
              onPressed: _fitMarkersInView,
              child: const Icon(Icons.fit_screen),
            )
          : null,
    );
  }

  void _showLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('คำอธิบายสีหมุด'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLegendItem('บ้านของพ่อแม่', Colors.blue),
              _buildLegendItem('บ้านญาติ', Colors.green),
              _buildLegendItem('บ้านผู้ปกครอง', Colors.orange),
              _buildLegendItem('วัด', Colors.purple),
              _buildLegendItem('มูลนิธิ', Colors.cyan),
              _buildLegendItem('หอพัก', Colors.yellow),
              _buildLegendItem('โรงงาน', Colors.pink),
              _buildLegendItem('บ้านนายจ้าง', Colors.deepPurple),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
