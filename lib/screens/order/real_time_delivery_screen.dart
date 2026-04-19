import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../chat/chat_screen.dart';
import 'safety_checklist_starting_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RealTimeDeliveryScreen — Full production navigation screen.
//
// Key behaviours mandated by spec:
//  • GPS via getPositionStream (NEVER getCurrentPosition + timer)
//  • Polyline fetched ONCE; only re-fetched when driver deviates > 100 m
//  • Marker animates smoothly using LatLng lerp over 500 ms
//  • Camera follows driver with tilt:45, zoom:16, bearing:heading
//  • Supabase UPSERT to driver_locations + drivers (throttled 3 s)
// ─────────────────────────────────────────────────────────────────────────────
class RealTimeDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic>? order;

  const RealTimeDeliveryScreen({super.key, this.order});

  @override
  State<RealTimeDeliveryScreen> createState() => _RealTimeDeliveryScreenState();
}

class _RealTimeDeliveryScreenState extends State<RealTimeDeliveryScreen>
    with TickerProviderStateMixin {
  // ── Map ────────────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = []; // stored in memory after first fetch

  // ── GPS stream ────────────────────────────────────────────────────────────
  final DriverLocationStream _gpsTracker = DriverLocationStream();

  // ── Smooth marker animation ───────────────────────────────────────────────
  AnimationController? _markerAnimController;
  Animation<double>? _markerAnim;
  LatLng? _prevMarkerPos; // interpolation start
  LatLng? _currentMarkerPos; // interpolation end (latest GPS fix)

  // ── State flags ───────────────────────────────────────────────────────────
  bool _locationPermissionDenied = false;
  bool _gpsDisabled = false;
  bool _isLoadingRoute = false;
  bool _routeFetched = false;
  bool _isArrived = false;

  // ── Stats ──────────────────────────────────────────────────────────────────
  double _distanceKm = 0.0;
  int _estimatedMinutes = 0;
  String _etaTime = '--:--';

  // ── Driver profile ────────────────────────────────────────────────────────
  String _driverName = 'Loading...';
  String? _avatarUrl;
  double _driverRating = 4.9;
  int _totalDeliveries = 0;

  // ── Destination (mutable — resolved async) ───────────────────────────────
  double? _destLat;
  double? _destLng;
  String _destAddress = 'Customer Location';
  String? _customerPhone;
  bool _isResolvingDestination = false;
  bool _destinationMissing = false;

  // -- Directions API (direct HTTP call -- no third-party package) ----------
  final String _apiKey = dotenv.env['MAPS_API_KEY'] ?? '';

  // ── Map style ─────────────────────────────────────────────────────────────
  static const String _mapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#f5f5f5"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#dadada"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9c9c9"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]}
]
''';

  @override
  void initState() {
    super.initState();

    // Marker animation controller
    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fetchDriverData();
    _startLocationStream();
    _resolveDestination(); // async — resolves lat/lng from order
  }

  @override
  void dispose() {
    _gpsTracker.dispose();
    _markerAnimController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  double? _parseDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  // ── Resolve destination — tries every known column name, re-fetches from
  //    Supabase if needed, falls back to Geocoding API. ──────────────────────
  Future<void> _resolveDestination() async {
    if (_isResolvingDestination) return;
    if (mounted) setState(() => _isResolvingDestination = true);

    final order = widget.order;
    final orderId = order?['id']?.toString();
    debugPrint('[Order Fetch] Resolving destination for order: $orderId');

    // ── Step 1: Try every column name variant present in the passed map ───
    final allLatKeys = [
      'customer_lat', 'delivery_lat', 'latitude', 'delivery_latitude',
      'lat', 'dest_lat', 'dropoff_lat',
    ];
    final allLngKeys = [
      'customer_lng', 'delivery_lng', 'longitude', 'delivery_longitude',
      'lng', 'dest_lng', 'dropoff_lng',
    ];

    double? lat;
    double? lng;

    if (order != null) {
      for (final k in allLatKeys) {
        final v = _parseDouble(order[k]);
        if (v != null && v != 0.0) { lat = v; break; }
      }
      for (final k in allLngKeys) {
        final v = _parseDouble(order[k]);
        if (v != null && v != 0.0) { lng = v; break; }
      }
    }

    final address = order?['delivery_address']?.toString() ??
        order?['address']?.toString() ?? '';
    _customerPhone = order?['customer_phone']?.toString();

    // ── Step 2: Re-fetch full order row from Supabase (realtime payloads
    //    may have incomplete records) ─────────────────────────────────────
    if ((lat == null || lng == null) && orderId != null) {
      debugPrint('[Order Fetch] Lat/lng missing in passed map — re-fetching order $orderId from Supabase');
      try {
        final fresh = await Supabase.instance.client
            .from('orders')
            .select()
            .eq('id', orderId)
            .maybeSingle();
        if (fresh != null) {
          debugPrint('[Order Fetch] Fresh order columns: ${fresh.keys.toList()}');
          for (final k in allLatKeys) {
            final v = _parseDouble(fresh[k]);
            if (v != null && v != 0.0) { lat = v; break; }
          }
          for (final k in allLngKeys) {
            final v = _parseDouble(fresh[k]);
            if (v != null && v != 0.0) { lng = v; break; }
          }
          // Also grab address / phone if not yet set
          final freshAddress = fresh['delivery_address']?.toString() ??
              fresh['address']?.toString() ?? address;
          final freshPhone = fresh['customer_phone']?.toString() ?? _customerPhone;
          if (mounted) {
            setState(() {
              _destAddress = freshAddress.isNotEmpty ? freshAddress : 'Customer Location';
              _customerPhone = freshPhone;
            });
          }
        }
      } catch (e) {
        debugPrint('[Order Fetch] Supabase re-fetch error: $e');
      }
    } else if (address.isNotEmpty) {
      if (mounted) setState(() => _destAddress = address);
    }

    // ── Step 3: Geocode address → lat/lng if still missing ────────────────
    if ((lat == null || lng == null) && _destAddress.isNotEmpty && _apiKey.isNotEmpty) {
      debugPrint('[Destination ERROR] No lat/lng in DB — attempting Geocoding for: "$_destAddress"');
      try {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=${Uri.encodeComponent(_destAddress)}&key=$_apiKey',
        );
        final resp = await http.get(uri).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final results = data['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final loc = results.first['geometry']['location'];
            lat = (loc['lat'] as num).toDouble();
            lng = (loc['lng'] as num).toDouble();
            debugPrint('[Destination Loaded] Geocoded: $lat, $lng');

            // Cache back into DB so future fetches have it
            if (orderId != null) {
              _cacheCoordinatesInDb(orderId, lat, lng);
            }
          }
        }
      } catch (e) {
        debugPrint('[Destination ERROR] Geocoding failed: $e');
      }
    }

    // ── Step 4: Final result ──────────────────────────────────────────────
    if (lat != null && lng != null) {
      debugPrint('[Destination Loaded] lat=$lat, lng=$lng address=$_destAddress');
      if (mounted) {
        setState(() {
          _destLat = lat;
          _destLng = lng;
          _isResolvingDestination = false;
          _destinationMissing = false;
        });
      }
      // Trigger first route once destination is known & we have GPS
      if (_currentMarkerPos != null) {
        final fakePos = await Geolocator.getLastKnownPosition();
        if (fakePos != null && !_routeFetched) _fetchRoute(fakePos);
      }
    } else {
      debugPrint('[Destination ERROR] Missing lat/lng — cannot draw route');
      if (mounted) {
        setState(() {
          _isResolvingDestination = false;
          _destinationMissing = true;
        });
      }
    }
  }

  /// Cache geocoded coordinates back into the orders table so future fetches
  /// don't need to geocode again.
  Future<void> _cacheCoordinatesInDb(String orderId, double lat, double lng) async {
    try {
      // Try the most common column name — this is a best-effort write
      await Supabase.instance.client.from('orders').update({
        'delivery_lat': lat,
        'delivery_lng': lng,
      }).eq('id', orderId);
      debugPrint('[Order Fetch] Cached geocoded coords to orders.$orderId');
    } catch (e) {
      debugPrint('[Order Fetch] Cache write failed (column may not exist): $e');
    }
  }

  // ── Driver profile fetch ──────────────────────────────────────────────────
  Future<void> _fetchDriverData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final profile = await Supabase.instance.client
          .from('drivers')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null && mounted) {
        setState(() {
          _driverName = profile['full_name'] ?? 'Driver';
          _avatarUrl = profile['avatar_url'];
          _driverRating = (profile['rating'] as num?)?.toDouble() ?? 4.9;
          _totalDeliveries = (profile['total_deliveries'] as num?)?.toInt() ?? 0;
        });
      } else if (mounted) {
        final user2 = Supabase.instance.client.auth.currentUser;
        setState(
            () => _driverName = user2?.email?.split('@')[0] ?? 'Driver');
      }
    } catch (e) {
      debugPrint('[RealTimeDelivery] profile fetch error: $e');
    }
  }

  // ── Start GPS stream ──────────────────────────────────────────────────────
  Future<void> _startLocationStream() async {
    final ok = await _gpsTracker.start(
      dbThrottleSeconds: 3,
      onPosition: _onNewPosition,
    );

    if (!ok && mounted) {
      final svcEnabled = await Geolocator.isLocationServiceEnabled();
      setState(() {
        _gpsDisabled = !svcEnabled;
        _locationPermissionDenied = svcEnabled; // service is on but perm denied
      });
    }
  }

  // ── Handle every new GPS position ─────────────────────────────────────────
  void _onNewPosition(Position pos) {
    if (!mounted) return;

    final newLatLng = LatLng(pos.latitude, pos.longitude);

    // --- Smooth marker animation -------------------------------------------
    final from = _currentMarkerPos ?? newLatLng;
    _prevMarkerPos = from;
    _currentMarkerPos = newLatLng;

    _markerAnimController?.reset();
    _markerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _markerAnimController!, curve: Curves.easeInOut),
    )..addListener(() {
        if (!mounted) return;
        final t = _markerAnim!.value;
        final interp = _lerpLatLng(_prevMarkerPos!, _currentMarkerPos!, t);
        _updateDriverMarker(interp, pos.heading);
      });
    _markerAnimController?.forward();

    // --- Stats ---------------------------------------------------------------
    if (_destLat != null && _destLng != null) {
      _updateStats(pos);
    }

    // --- Camera follow -------------------------------------------------------
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: newLatLng,
        zoom: 16,
        tilt: 45,
        bearing: pos.heading,
      )),
    );

    // --- Arrival check -------------------------------------------------------
    final dLatCheck = _destLat;
    final dLngCheck = _destLng;
    if (dLatCheck != null && dLngCheck != null) {
      final dist = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, dLatCheck, dLngCheck,
      );
      if (mounted) setState(() => _isArrived = dist < 80);
    }

    // --- Smart polyline refresh (ONLY if deviated > 100 m from route) --------
    if (_routeFetched && _routePoints.isNotEmpty) {
      final nearestDist = _distanceToPolyline(newLatLng, _routePoints);
      if (nearestDist > 100) {
        debugPrint('[Route Fetch] Driver deviated ${nearestDist.toStringAsFixed(0)} m — re-fetching route');
        _fetchRoute(pos);
      }
    } else if (!_routeFetched && !_isLoadingRoute &&
        _destLat != null && _destLng != null) {
      // First-time fetch
      _fetchRoute(pos);
    }
  }

  // ── LatLng linear interpolation (smooth marker movement) ─────────────────
  LatLng _lerpLatLng(LatLng a, LatLng b, double t) {
    return LatLng(
      lerpDouble(a.latitude, b.latitude, t)!,
      lerpDouble(a.longitude, b.longitude, t)!,
    );
  }

  // ── Nearest distance (meters) from point to any polyline segment ──────────
  double _distanceToPolyline(LatLng point, List<LatLng> poly) {
    if (poly.isEmpty) return double.infinity;
    double minDist = double.infinity;
    for (final pt in poly) {
      final d = Geolocator.distanceBetween(
          point.latitude, point.longitude, pt.latitude, pt.longitude);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  // ── Update driver marker on map ───────────────────────────────────────────
  void _updateDriverMarker(LatLng pos, double heading) {
    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor: const Offset(0.5, 0.5),
        rotation: heading,
        flat: true,
        zIndexInt: 2,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ));
    });
  }

  // ── Stats (distance + ETA) ────────────────────────────────────────────────
  void _updateStats(Position pos) {
    final dLat = _destLat;
    final dLng = _destLng;
    if (dLat == null || dLng == null) return;
    final distM = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, dLat, dLng);
    final km = distM / 1000.0;
    final mins = math.max(1, (km / 30.0 * 60.0).ceil());
    final arrival = DateTime.now().add(Duration(minutes: mins));
    final h = arrival.hour > 12
        ? arrival.hour - 12
        : (arrival.hour == 0 ? 12 : arrival.hour);
    final m = arrival.minute.toString().padLeft(2, '0');
    final ampm = arrival.hour >= 12 ? 'PM' : 'AM';
    if (mounted) {
      setState(() {
        _distanceKm = km;
        _estimatedMinutes = mins;
        _etaTime = '$h:$m $ampm';
      });
    }
  }

  // -- Google Directions API: decode encoded polyline string ----------------
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dLat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dLng;
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  // -- Fetch Google Directions API route ------------------------------------
  Future<void> _fetchRoute(Position driverPos) async {
    final dLat = _destLat;
    final dLng = _destLng;

    if (dLat == null || dLng == null) {
      debugPrint('[Route ERROR] Destination missing -- cannot fetch route');
      return;
    }
    if (_isLoadingRoute) return;

    debugPrint('[Route Input] driver: ${driverPos.latitude},${driverPos.longitude}');
    debugPrint('[Route Input] destination: $dLat,$dLng');

    if (mounted) setState(() => _isLoadingRoute = true);

    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${driverPos.latitude},${driverPos.longitude}'
        '&destination=$dLat,$dLng'
        '&mode=driving'
        '&key=$_apiKey',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (!mounted) return;

      if (response.statusCode != 200) {
        debugPrint('[Route API Response] HTTP error ${response.statusCode}');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'UNKNOWN';
      debugPrint('[Route API Response] status=$status');

      if (status != 'OK') {
        debugPrint('[Route ERROR] API status=$status -- ${data['error_message'] ?? 'no details'}');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        debugPrint('[Route ERROR] No routes returned');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      final encodedPolyline =
          (routes[0]['overview_polyline']['points'] as String?) ?? '';
      final previewLen = encodedPolyline.length > 80 ? 80 : encodedPolyline.length;
      debugPrint('[Polyline Raw] ${encodedPolyline.substring(0, previewLen)}...');

      if (encodedPolyline.isEmpty) {
        debugPrint('[Polyline ERROR] Empty polyline string');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      final decodedPoints = _decodePolyline(encodedPolyline);
      debugPrint('[Polyline Points] count = ${decodedPoints.length}');

      if (decodedPoints.length < 2) {
        debugPrint('[Polyline ERROR] Too few points: ${decodedPoints.length}');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      _routePoints
        ..clear()
        ..addAll(decodedPoints);

      _markers.removeWhere((m) => m.markerId.value == 'destination');
      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(dLat, dLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: _destAddress),
        zIndexInt: 1,
      ));

      debugPrint('[Polyline Drawn] ${decodedPoints.length} points rendered on map');

      setState(() {
        _routeFetched = true;
        _isLoadingRoute = false;
        _polylines
          ..clear()
          ..add(Polyline(
            polylineId: const PolylineId('route'),
            color: const Color(0xFF4285F4),
            points: List<LatLng>.from(decodedPoints),
            width: 6,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ));
      });
    } catch (e) {
      debugPrint('[Route ERROR] Exception: $e');
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  // ── Map created ───────────────────────────────────────────────────────────
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // If we already have a driver position, zoom to it; otherwise show dest
    final dLatV = _destLat;
    final dLngV = _destLng;
    if (_currentMarkerPos != null && dLatV != null && dLngV != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          math.min(_currentMarkerPos!.latitude, dLatV),
          math.min(_currentMarkerPos!.longitude, dLngV),
        ),
        northeast: LatLng(
          math.max(_currentMarkerPos!.latitude, dLatV),
          math.max(_currentMarkerPos!.longitude, dLngV),
        ),
      );
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  }

  // ── Navigate in Google Maps ───────────────────────────────────────────────
  Future<void> _openGoogleMaps() async {
    if (_destLat == null || _destLng == null) return;
    final url =
        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$_destLat,$_destLng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ── Call customer ─────────────────────────────────────────────────────────
  Future<void> _callCustomer() async {
    final phone = _customerPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available.')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── Arrived button handler ────────────────────────────────────────────────
  Future<void> _onArrived() async {
    final orderId = widget.order?['id']?.toString();
    if (orderId != null) {
      try {
        final now = DateTime.now().toUtc().toIso8601String();
        await Supabase.instance.client.from('orders').update({
          'status': 'assigned',
          'arrived_at': now,
        }).eq('id', orderId);
        widget.order?['status'] = 'assigned';
        widget.order?['arrived_at'] = now;

        final userId = widget.order?['user_id']?.toString();
        if (userId != null && userId.isNotEmpty) {
          NotificationService.notifyUserDriverArrived(userId, orderId);
        }
      } catch (e) {
        debugPrint('[RealTimeDelivery] arrived update error: $e');
      }
    }
    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            SafetyChecklistStartingScreen(order: widget.order),
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // ── Permission / GPS error screens ─────────────────────────────────────
    if (_gpsDisabled) return _errorScreen('GPS is disabled', 'Please turn on Location Services in your device settings.', Icons.location_disabled_rounded);
    if (_locationPermissionDenied) {
      return _errorScreen(
        'Location Permission Denied',
        'FuelDirect needs location access to navigate. Tap below to open Settings.',
        Icons.lock_rounded,
        actionLabel: 'Open Settings',
        onAction: () async {
          await Geolocator.openAppSettings();
        },
      );
    }

    final dLatV = _destLat;
    final dLngV = _destLng;
    final LatLng initialTarget = (dLatV != null && dLngV != null)
        ? LatLng(dLatV, dLngV)
        : _currentMarkerPos ??
            const LatLng(24.8607, 67.0011); // Karachi fallback

    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ──────────────────────────────────────────────────
          Positioned.fill(
            child: GoogleMap(
              mapType: MapType.normal,
              style: _mapStyle,
              initialCameraPosition:
                  CameraPosition(target: initialTarget, zoom: 14),
              myLocationEnabled: false, // we control the marker ourselves
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              markers: Set<Marker>.of(_markers),
              polylines: Set<Polyline>.of(_polylines),
              onMapCreated: _onMapCreated,
            ),
          ),

          // ── Subtle gradient overlay (top + bottom) ───────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.12),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                    stops: const [0, 0.15, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ── Route loading indicator ──────────────────────────────────────
          if (_isLoadingRoute)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                color: Color(0xFFFF4D00),
                backgroundColor: Colors.transparent,
              ),
            ),

          // ── Destination resolving banner ─────────────────────────────────
          if (_isResolvingDestination)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: const Color(0xFFFF4D00).withValues(alpha: 0.9),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 10),
                    Text('Locating delivery address…',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),

          // ── Destination missing overlay ──────────────────────────────────
          if (_destinationMissing && !_isResolvingDestination)
            Positioned(
              bottom: 240,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off_rounded,
                        color: Color(0xFFFF4D00), size: 36),
                    const SizedBox(height: 10),
                    const Text('Delivery location not available',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF1F1F1F))),
                    const SizedBox(height: 6),
                    Text(
                        _destAddress.isNotEmpty
                            ? 'Address: $_destAddress'
                            : 'No address on record for this order.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF888888))),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _resolveDestination,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4D00),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Top controls ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _circleBtn(Icons.arrow_back_ios_new,
                          () => Navigator.of(context).pop(),
                          size: 18),
                      GestureDetector(
                        onTap: _openGoogleMaps,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4D00),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4D00).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.navigation_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text('Navigate',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Destination card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE8DD),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.location_on_rounded,
                              color: Color(0xFFFF4D00), size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Delivering to',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF888888),
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(
                                _destAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F1F1F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom UI ────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Stats row ───────────────────────────────────────────
                  Row(
                    children: [
                      _statBox('ETA', _etaTime),
                      const SizedBox(width: 10),
                      _statBox('TIME', '$_estimatedMinutes min'),
                      const SizedBox(width: 10),
                      _statBox(
                          'DIST',
                          _distanceKm > 0
                              ? '${_distanceKm.toStringAsFixed(1)} km'
                              : '--'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Driver/Customer info card ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(
                            _avatarUrl != null && _avatarUrl!.isNotEmpty
                                ? _avatarUrl!
                                : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=100&auto=format',
                          ),
                          backgroundColor: const Color(0xFFEEEEEE),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_driverName,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1F1F1F))),
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.star,
                                    color: Color(0xFFFFB800), size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  _driverRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFFB800)),
                                ),
                                const SizedBox(width: 4),
                                Text('($_totalDeliveries deliveries)',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF888888),
                                        fontWeight: FontWeight.w500)),
                              ]),
                            ],
                          ),
                        ),
                        // Chat
                        GestureDetector(
                          onTap: () {
                            final order = widget.order;
                            final userId = order?['user_id']?.toString();
                            if (userId != null && order != null) {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (c) => ChatScreen(
                                  orderId: order['id'].toString(),
                                  customerId: userId,
                                  customerName: order['customer_name']
                                          ?.toString() ??
                                      'Customer',
                                ),
                              ));
                            }
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                                color: Colors.blue[600],
                                shape: BoxShape.circle),
                            child: const Icon(Icons.chat_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Call
                        GestureDetector(
                          onTap: _callCustomer,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                                color: Color(0xFFFF4D00),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.phone_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Arrived button ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _onArrived,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isArrived
                            ? Colors.green.shade600
                            : const Color(0xFFFF4D00),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isArrived
                                ? Icons.check_circle_rounded
                                : Icons.location_on_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isArrived
                                ? 'Arrived! Confirm Arrival'
                                : 'Arrived at Customer',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────────

  Widget _circleBtn(IconData icon, VoidCallback onTap, {double size = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.10), blurRadius: 10),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1F1F1F), size: size),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4D00),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ── Full-screen error widget ──────────────────────────────────────────────
  Widget _errorScreen(
    String title,
    String subtitle,
    IconData icon, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 72, color: const Color(0xFFFF4D00)),
              const SizedBox(height: 24),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F1F1F))),
              const SizedBox(height: 12),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, color: Color(0xFF888888), height: 1.5)),
              const SizedBox(height: 32),
              if (actionLabel != null && onAction != null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(actionLabel,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back',
                    style: TextStyle(
                        color: Color(0xFFFF4D00), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
