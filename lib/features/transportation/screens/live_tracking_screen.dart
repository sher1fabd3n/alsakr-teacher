import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../services/api_client.dart';
import '../models/transportation_models.dart';
import '../services/bus_tracking_signalr_service.dart';
import '../services/transportation_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key, this.studentId, this.tripId});

  final int? studentId;
  final int? tripId;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final _mapController = MapController();
  final _signalR = BusTrackingSignalRService();
  LiveTrackingData? _tracking;
  LatLng? _parentLocation;
  LatLng? _busLocation;
  bool _loading = true;
  String? _error;
  bool _isNoActiveTrip = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final transport = context.read<TransportationService>();
      final api = context.read<ApiClient>();
      final token = await api.readToken();
      _tracking = await transport.getLiveTracking(studentId: widget.studentId);

      if (_tracking?.busLatitude != null && _tracking?.busLongitude != null) {
        _busLocation = LatLng(_tracking!.busLatitude!, _tracking!.busLongitude!);
      }

      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        final pos = await Geolocator.getCurrentPosition();
        _parentLocation = LatLng(pos.latitude, pos.longitude);
      } catch (_) {}

      if (token != null && _tracking != null) {
        await _signalR.connect(transport, token);
        await _signalR.joinTrip(_tracking!.tripId);
        _signalR.onBusLocationUpdated = ({
          required tripId,
          required latitude,
          required longitude,
          speedKmh,
          heading,
          status,
        }) {
          if (!mounted) return;
          setState(() {
            _busLocation = LatLng(latitude, longitude);
            _tracking = LiveTrackingData(
              tripId: _tracking!.tripId,
              tripStatus: status ?? _tracking!.tripStatus,
              tripType: _tracking!.tripType,
              busLatitude: latitude,
              busLongitude: longitude,
              busSpeedKmh: speedKmh,
              busHeading: heading,
              lastLocationAt: DateTime.now(),
              routeName: _tracking!.routeName,
              busNumber: _tracking!.busNumber,
              driverName: _tracking!.driverName,
              driverPhone: _tracking!.driverPhone,
              supervisorName: _tracking!.supervisorName,
              supervisorPhone: _tracking!.supervisorPhone,
              studentPickupLatitude: _tracking!.studentPickupLatitude,
              studentPickupLongitude: _tracking!.studentPickupLongitude,
              distanceRemainingKm: _tracking!.distanceRemainingKm,
              etaMinutes: _tracking!.etaMinutes,
              studentTripStatus: _tracking!.studentTripStatus,
              stops: _tracking!.stops,
            );
          });
          _mapController.move(_busLocation!, _mapController.camera.zoom);
        };
      }

      _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
        try {
          final latest = await transport.getLiveTracking(studentId: widget.studentId);
          if (!mounted) return;
          setState(() {
            _tracking = latest;
            if (latest.busLatitude != null && latest.busLongitude != null) {
              _busLocation = LatLng(latest.busLatitude!, latest.busLongitude!);
            }
          });
        } catch (_) {}
      });

      _focusMap();
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is NoActiveTripException
            ? e.toString()
            : e.toString().replaceFirst('Exception: ', '');
        _isNoActiveTrip = e is NoActiveTripException;
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = null;
      _isNoActiveTrip = false;
    });
    await _bootstrap();
  }

  void _focusMap() {
    final points = <LatLng>[];
    if (_busLocation != null) points.add(_busLocation!);
    if (_parentLocation != null) points.add(_parentLocation!);
    if (_tracking?.studentPickupLatitude != null && _tracking?.studentPickupLongitude != null) {
      points.add(LatLng(_tracking!.studentPickupLatitude!, _tracking!.studentPickupLongitude!));
    }
    if (points.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(60),
        ),
      );
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _signalR.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع الحافلة'),
        actions: [
          IconButton(
            onPressed: _focusMap,
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _TrackingEmptyState(
                  message: _error!,
                  isNoActiveTrip: _isNoActiveTrip,
                  onRetry: _retry,
                )
              : Column(
                  children: [
                    Expanded(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: LatLng(31.1294, 30.6472),
                          initialZoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.alsakr.students',
                          ),
                          if (_tracking != null && _tracking!.stops.length >= 2)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _tracking!.stops
                                      .map((s) => LatLng(s.latitude, s.longitude))
                                      .toList(),
                                  color: AppColors.primary,
                                  strokeWidth: 4,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              if (_busLocation != null)
                                Marker(
                                  point: _busLocation!,
                                  width: 48,
                                  height: 48,
                                  child: const Icon(Icons.directions_bus_rounded, color: Colors.red, size: 40),
                                ),
                              if (_parentLocation != null)
                                Marker(
                                  point: _parentLocation!,
                                  width: 36,
                                  height: 36,
                                  child: const Icon(Icons.person_pin_circle_rounded, color: AppColors.secondary, size: 34),
                                ),
                              if (_tracking?.studentPickupLatitude != null &&
                                  _tracking?.studentPickupLongitude != null)
                                Marker(
                                  point: LatLng(
                                    _tracking!.studentPickupLatitude!,
                                    _tracking!.studentPickupLongitude!,
                                  ),
                                  width: 36,
                                  height: 36,
                                  child: const Icon(Icons.home_rounded, color: AppColors.accent, size: 32),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_tracking != null) _InfoPanel(tracking: _tracking!),
                  ],
                ),
    );
  }
}

class _TrackingEmptyState extends StatelessWidget {
  const _TrackingEmptyState({
    required this.message,
    required this.isNoActiveTrip,
    required this.onRetry,
  });

  final String message;
  final bool isNoActiveTrip;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNoActiveTrip
                    ? Icons.directions_bus_filled_rounded
                    : Icons.error_outline_rounded,
                size: 44,
                color: isNoActiveTrip ? AppColors.primary : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isNoActiveTrip ? 'لا توجد رحلة نشطة' : 'تعذر تحميل التتبع',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              isNoActiveTrip
                  ? 'لم يبدأ السائق رحلة لهذا الطالب بعد.\nيمكنك المحاولة لاحقاً عند بدء الرحلة.'
                  : message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.tracking});

  final LiveTrackingData tracking;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${tracking.routeName} • ${tracking.busNumber}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _chip('الحالة', tracking.tripStatus),
              const SizedBox(width: 8),
              if (tracking.etaMinutes != null) _chip('الوصول', '${tracking.etaMinutes} د'),
              if (tracking.distanceRemainingKm != null)
                _chip('المسافة', '${tracking.distanceRemainingKm!.toStringAsFixed(1)} كم'),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.person_rounded, color: AppColors.primary),
              title: Text(tracking.driverName, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('سائق • ${tracking.driverPhone}'),
            ),
          ),
          if (tracking.supervisorName != null)
            AppCard(
              child: ListTile(
                leading: const Icon(Icons.supervisor_account_rounded, color: AppColors.secondary),
                title: Text(tracking.supervisorName!, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('مشرف • ${tracking.supervisorPhone ?? ''}'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('$label: $value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      );
}
