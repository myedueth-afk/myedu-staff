import 'dart:convert';

import 'package:eschool_saas_staff/data/models/pickupPoint.dart';
import 'package:eschool_saas_staff/data/models/transportDashboard.dart';
import 'package:eschool_saas_staff/data/models/transportFee.dart';
import 'package:eschool_saas_staff/data/models/transportShift.dart';
import 'package:eschool_saas_staff/data/models/vehicleAssignmentStatus.dart';
import 'package:eschool_saas_staff/data/models/trip.dart';
import 'package:eschool_saas_staff/utils/api.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/unauthenticatedAccessManager.dart';
import 'package:flutter/material.dart';

/// A location update that did not get through.
///
/// [isRetryable] is what the tracker branches on. An update that never reached
/// the server — no connectivity, a timeout, a server fault — is worth repeating
/// on the next interval. A refusal from the server itself, on the other hand,
/// will be refused again just as certainly: the trip is over, or it was never
/// this driver's to update. Repeating that would drain battery and data for
/// nothing, so tracking stops instead.
class TripLocationException implements Exception {
  final String message;
  final bool isRetryable;

  const TripLocationException(this.message, {this.isRetryable = true});

  @override
  String toString() => message;
}

class TransportRepository {
  Future<List<PickupPoint>> getPickupPoints() async {
    try {
      final result = await Api.get(url: Api.getPickupPoints);
      return ((result['data'] ?? []) as List)
          .map((e) => PickupPoint.fromJson(Map<String, dynamic>.from(e ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<TransportShift>> getShifts({required int pickupPointId}) async {
    try {
      final result = await Api.get(
          url: Api.getTransportationShifts,
          queryParameters: {"pickup_point_id": pickupPointId});
      return ((result['data'] ?? []) as List)
          .map((e) =>
              TransportShift.fromJson(Map<String, dynamic>.from(e ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<TransportFeesResponse> getFees({required int pickupPointId}) async {
    try {
      final result = await Api.get(
          url: Api.getTransportationFees,
          queryParameters: {"pickup_point_id": pickupPointId});
      return TransportFeesResponse.fromJson(result);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<TransportDashboard> getDashboard({
    required int userId,
  }) async {
    try {
      final result = await Api.post(
        url: Api.getTransportDashboard,
        useAuthToken: true,
        body: {
          'user_id': userId.toString(),
        },
      );

      return TransportDashboard.fromJson(
        Map<String, dynamic>.from(result['data'] ?? {}),
      );
    } catch (e, st) {
      debugPrint("this is the error: $e");
      debugPrint("this is the stack trace: $st");
      throw ApiException(e.toString());
    }
  }

  Future<VehicleAssignmentStatus> getVehicleAssignmentStatus({
    required int userId,
  }) async {
    try {
      final result = await Api.post(
        url: Api.getVehicleAssignmentStatus,
        useAuthToken: true,
        body: {
          'user_id': userId.toString(),
        },
      );

      return VehicleAssignmentStatus.fromJson(result);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  // Trip related methods
  Future<List<Trip>> getTrips() async {
    try {
      final result = await Api.get(
        url: Api.getTrips,
        useAuthToken: true,
      );

      return ((result['data'] ?? []) as List)
          .map((trip) => Trip.fromJson(Map<String, dynamic>.from(trip ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<Trip>> getTripsByRoute({required int routeId}) async {
    try {
      final result = await Api.get(
        url: Api.getTrips,
        useAuthToken: true,
        queryParameters: {
          'route_id': routeId,
        },
      );

      return ((result['data'] ?? []) as List)
          .map((trip) => Trip.fromJson(Map<String, dynamic>.from(trip ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Trip> getTripDetails({required int tripId}) async {
    try {
      final result = await Api.get(
        url: Api.getTrips,
        useAuthToken: true,
        queryParameters: {
          'trip_id': tripId,
        },
      );

      final tripData = result['data'];
      if (tripData is List && tripData.isNotEmpty) {
        return Trip.fromJson(Map<String, dynamic>.from(tripData.first ?? {}));
      } else if (tripData is Map) {
        return Trip.fromJson(Map<String, dynamic>.from(tripData));
      } else {
        throw ApiException('No trip data found');
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> startEndTrip({
    required int shiftId,
    required String pickupDrop, // "pickup" or "drop"
    required String startEnd, // "start" or "end"
    int? tripId, // Optional trip_id for ending trips
  }) async {
    try {
      final body = {
        'shift_id': shiftId.toString(),
        'pickup_drop': pickupDrop,
        'start_end': startEnd,
      };

      // Add trip_id to body when ending a trip
      if (tripId != null) {
        body['trip_id'] = tripId.toString();
      }

      final result = await Api.post(
        url: Api.startEndTrip,
        useAuthToken: true,
        body: body,
      );

      return result;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> createAttendance({
    required int routeVehicleId,
    required int pickupPointId,
    required int shiftId,
    required int pickupDrop, // 0 for pickup, 1 for drop
    required String date,
    required int tripId,
    required List<Map<String, dynamic>> records, // List of {user_id, status}
  }) async {
    try {
      final result = await Api.post(
        url: Api.createAttendance,
        useAuthToken: true,
        body: {
          'route_vehicle_id': routeVehicleId,
          'pickup_point_id': pickupPointId,
          'shift_id': shiftId,
          'pickup_drop': pickupDrop,
          'date': date,
          'trip_id': tripId,
          'records': records
        },
      );

      return result;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /// Reports where the vehicle is right now for an in-progress trip.
  ///
  /// Goes through the raw POST helper so the envelope can be read here: the
  /// endpoint answers with HTTP 200 even when it refuses, and only the `error`
  /// flag separates "the server said no" from "this never reached the server".
  /// That distinction is the whole point — see [TripLocationException].
  Future<void> updateTripLocation({
    required int tripId,
    required double latitude,
    required double longitude,
  }) async {
    final String rawResponse;
    try {
      rawResponse = await Api.postRaw(
        url: Api.updateTripLocation,
        useAuthToken: true,
        body: {
          'trip_id': tripId.toString(),
          // Fixed notation, six decimals: about 10 cm of precision, and never
          // the exponent form `double.toString` produces for a coordinate near
          // zero — which no numeric column would take.
          'latitude': latitude.toStringAsFixed(6),
          'longitude': longitude.toStringAsFixed(6),
        },
      );
    } on ApiException catch (e) {
      throw TripLocationException(e.errorMessage);
    } catch (e) {
      throw TripLocationException(e.toString());
    }

    final Map<String, dynamic> envelope;
    try {
      final decoded = jsonDecode(rawResponse);
      if (decoded is! Map) throw const FormatException();
      envelope = Map<String, dynamic>.from(decoded);
    } catch (_) {
      // A body we cannot read says nothing about the trip, so the next
      // interval is free to try again.
      throw const TripLocationException(defaultErrorMessageKey);
    }

    // `Api.postRaw` only sees the HTTP status, so a session that expired
    // mid-trip and comes back as a `code: 401` inside a 200 body is handled
    // here, the same way [Api.post] handles it for every other endpoint.
    if (int.tryParse((envelope['code'] ?? "").toString()) == 401) {
      UnauthenticatedAccessManager().handleUnauthorizedAccess();
      throw const TripLocationException(
        defaultErrorMessageKey,
        isRetryable: false,
      );
    }

    if (envelope['error']?.toString().toLowerCase() == "true") {
      final message = (envelope['message'] ?? "").toString();
      throw TripLocationException(
        message.isEmpty ? defaultErrorMessageKey : message,
        isRetryable: false,
      );
    }
  }
}
