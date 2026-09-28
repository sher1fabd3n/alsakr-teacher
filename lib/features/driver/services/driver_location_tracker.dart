import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../../../config/api_config.dart';
import '../../../services/api_client.dart';
import '../services/driver_service.dart';

class DriverBackgroundLocation {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  static Future<void> ensureInitialized() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) return;

    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'driver_tracking',
        initialNotificationTitle: 'تتبع رحلة الحافلة',
        initialNotificationContent: 'جاري إرسال الموقع',
        foregroundServiceNotificationId: 9911,
      ),
    );
  }

  static Future<void> startTripTracking(int tripId) async {
    await ensureInitialized();
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }
    service.invoke('startTrip', {'tripId': tripId});
  }

  static Future<void> stopTripTracking() async {
    final service = FlutterBackgroundService();
    service.invoke('stopTrip');
    if (await service.isRunning()) {
      service.invoke('stopService');
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
    ApiClient.attachSchoolHttps(dio);
    Timer? timer;
    int? tripId;

    Future<void> sendLocation() async {
      if (tripId == null) return;
      try {
        final token = await _storage.read(key: _tokenKey);
        if (token == null || token.isEmpty) return;
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        await dio.post(
          '/api/transportation/driver/trips/$tripId/location',
          data: {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'speedKmh': position.speed * 3.6,
            'heading': position.heading,
            'accuracyMeters': position.accuracy,
          },
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } catch (_) {}
    }

    service.on('startTrip').listen((event) {
      tripId = event?['tripId'] as int?;
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 8), (_) => sendLocation());
      sendLocation();
    });

    service.on('stopTrip').listen((_) {
      timer?.cancel();
      tripId = null;
    });

    service.on('stopService').listen((_) {
      timer?.cancel();
      service.stopSelf();
    });
  }
}

class DriverLocationTracker {
  DriverLocationTracker(this._driverService);

  final DriverService _driverService;
  Timer? _foregroundTimer;
  int? _tripId;

  Future<void> start(int tripId) async {
    _tripId = tripId;
    await _ensurePermission();
    await DriverBackgroundLocation.startTripTracking(tripId);

    _foregroundTimer?.cancel();
    _foregroundTimer = Timer.periodic(const Duration(seconds: 8), (_) => _tick());
    await _tick();
  }

  Future<void> stop() async {
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
    _tripId = null;
    await DriverBackgroundLocation.stopTripTracking();
  }

  Future<void> _tick() async {
    final tripId = _tripId;
    if (tripId == null) return;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _driverService.updateLocation(
        tripId,
        latitude: position.latitude,
        longitude: position.longitude,
        speedKmh: position.speed * 3.6,
        heading: position.heading,
        accuracyMeters: position.accuracy,
      );
    } catch (_) {}
  }

  Future<void> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('يجب السماح بالموقع لتتبع الرحلة.');
    }
  }
}
