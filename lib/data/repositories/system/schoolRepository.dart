import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:eschool/data/models/system/gallery.dart';
import 'package:eschool/data/models/system/schoolConfiguration.dart';
import 'package:eschool/data/models/academic/sessionYear.dart';
import 'package:eschool/data/models/system/sliderDetails.dart';
import 'package:eschool/utils/system/api.dart';

class SchoolRepository {
  Future<SchoolConfiguration> getSchoolSchoolSettingDetails(
      {required bool useParentApi, int? childId}) async {
    try {
      final result = await Api.get(
          url: useParentApi
              ? Api.getParentChildSchoolSettingDetails
              : Api.getSchoolSettingDetails,
          useAuthToken: true,
          queryParameters: useParentApi ? {"child_id": childId ?? 0} : {});

      // print(result);
      final prettyJson = JsonEncoder.withIndent('    ').convert(result);
      final lines = prettyJson.split('\n');
      for (var line in lines) {
        print(line);
      }

      return SchoolConfiguration.fromJson(Map.from(result['data'] ?? {}));
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<SliderDetails>> fetchSliders(
      {required bool useParentApi, int? childId}) async {
    try {
      Map<String, dynamic> body = {};

      if (useParentApi) {
        body['child_id'] = childId ?? 0;
      }

      final result = await Api.get(
          queryParameters: body,
          url: useParentApi ? Api.getParentSliders : Api.getStudentSliders,
          useAuthToken: true);

      // === DEBUG: Log raw API response structure ===
      debugPrint("=== SLIDERS RAW RESPONSE ===");
      debugPrint("result type: ${result.runtimeType}");
      debugPrint("result keys: ${result.keys.toList()}");
      debugPrint("result['data'] type: ${result['data'].runtimeType}");
      debugPrint("result['data'] value: ${result['data']}");
      // === END DEBUG ===

      // Handle paginated response: { "data": { "data": [...] } }
      final dynamic rawData = result['data'];
      final List sliderList;
      if (rawData is List) {
        sliderList = rawData;
      } else if (rawData is Map && rawData.containsKey('data')) {
        debugPrint("=== SLIDERS: Detected paginated response! Unwrapping inner 'data' ===");
        sliderList = rawData['data'] as List;
      } else {
        debugPrint("=== SLIDERS: Unexpected data format, defaulting to empty ===");
        sliderList = [];
      }

      final sliders = sliderList
          .map((sliderDetails) => SliderDetails.fromJson(Map<String, dynamic>.from(sliderDetails)))
          .toList();
      debugPrint("=== SLIDERS PARSED COUNT: ${sliders.length} ===");
      return sliders;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<Gallery>> fetchSchoolGallery(
      {required bool useParentApi,
      int? childId,
      required int sessionYearId,
      int? galleryId}) async {
    try {
      final result = await Api.get(
          url: Api.getSchoolGallery,
          useAuthToken: true,
          queryParameters: {
            "session_year_id": sessionYearId,
            "child_id": useParentApi ? childId : null,
            "gallery_id": galleryId
          });

      return ((result['data'] ?? []) as List)
          .map((gallery) => Gallery.fromJson(gallery ?? {}))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<SessionYear>> fetchSchoolSessionYears(
      {required bool useParentApi, int? childId}) async {
    try {
      final result = await Api.get(
          url: Api.getSchoolSessionYears,
          useAuthToken: true,
          queryParameters: {
            "child_id": useParentApi ? childId : null,
          });

      return ((result['data'] ?? []) as List)
          .map((sessionYear) => SessionYear.fromJson(sessionYear ?? {}))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
