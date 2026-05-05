// lib/widgets/location_picker_widget.dart
// Widget para seleccionar ubicación usando OpenStreetMap

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../constants.dart';

class LocationPickerWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const LocationPickerWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  late MapController _mapController;
  LatLng _selectedLocation = const LatLng(-17.3935, -66.1570); // Cochabamba, Bolivia default
  String _address = '';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Si hay ubicación inicial, usarla
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      _address = widget.initialAddress ?? '';
    }
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      // Verificar permisos
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están deshabilitados');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Permisos de ubicación denegados permanentemente. Por favor habilítelos en configuración.',
        );
      }

      // Obtener ubicación
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      // Centrar mapa en la ubicación
      _mapController.move(_selectedLocation, 16.0);
      
      // Obtener dirección
      await _getAddressFromCoordinates();
    } catch (e) {
      String errorMessage;
      
      if (e.toString().contains('serviceEnabled') || 
          e.toString().contains('servicios de ubicación')) {
        errorMessage = '📍 Por favor activa el GPS en tu dispositivo';
      } else if (e.toString().contains('deniedForever') || 
                 e.toString().contains('permanentemente')) {
        errorMessage = '⚙️ Los permisos de ubicación están bloqueados.\n\n'
            'Ve a Configuración → Aplicaciones → StructureScan → Permisos '
            'y activa "Ubicación"';
      } else if (e.toString().contains('denied') || 
                 e.toString().contains('denegados')) {
        errorMessage = '📍 Necesitamos permiso para acceder a tu ubicación.\n\n'
            'Por favor acepta cuando aparezca el mensaje.';
      } else if (e.toString().contains('manifest')) {
        errorMessage = '⚠️ Error de configuración.\n\n'
            'Por favor reinicia la aplicación.';
      } else {
        errorMessage = 'Error al obtener ubicación: ${e.toString()}';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: kRojoAdvertencia,
            duration: const Duration(seconds: 5),
            action: e.toString().contains('deniedForever')
                ? SnackBarAction(
                    label: 'Abrir Configuración',
                    textColor: Colors.white,
                    onPressed: () async {
                      // Abre configuración de la app
                      await Geolocator.openAppSettings();
                    },
                  )
                : null,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getAddressFromCoordinates() async {
    setState(() => _isLoadingAddress = true);
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _address = _formatAddress(place);
        });
      }
    } catch (e) {
      debugPrint('Error obteniendo dirección: $e');
      setState(() {
        _address = 'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}, '
            'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}';
      });
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  String _formatAddress(Placemark place) {
    List<String> parts = [];
    
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Ubicación seleccionada';
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    _getAddressFromCoordinates();
  }

  void _confirmLocation() {
    Navigator.of(context).pop({
      'address': _address.isNotEmpty ? _address : 'Ubicación seleccionada',
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        backgroundColor: kAzulPrincipalOscuro,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: kVerdeExito),
            onPressed: _confirmLocation,
            tooltip: 'Confirmar ubicación',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 15.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.structurescan_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: kRojoAdvertencia,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Panel de información
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: kBlanco,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dirección
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: kAzulSecundarioClaro),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isLoadingAddress
                            ? const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Obteniendo dirección...'),
                                ],
                              )
                            : Text(
                                _address.isNotEmpty
                                    ? _address
                                    : 'Toca el mapa para seleccionar ubicación',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingLocation ? null : _getUserLocation,
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location),
                          label: const Text('Mi Ubicación'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _confirmLocation,
                          icon: const Icon(Icons.check),
                          label: const Text('Confirmar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kVerdeExito,
                            foregroundColor: kBlanco,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Coordenadas (para debug)
                  Text(
                    'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}, '
                    'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: kGrisMedio,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
