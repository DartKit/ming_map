import 'package:app_kit/core/kt_export.dart';
// import 'package:flutter_bmflocation/flutter_bmflocation.dart';

MapToolLogic get cMapt => Get.isRegistered<MapToolLogic>() ? Get.find<MapToolLogic>() : Get.put<MapToolLogic>(MapToolLogic());

class MapToolLogic extends GetxController {
  // var map = BMFMapController.withId(5000).obs;
  // var poLine0 = BMFPolyline(coordinates: [BMFCoordinate(0.0, 0.0),BMFCoordinate(1.0, 1.0)], indexs: [0]).obs;
  //
  // BMFPolyline get resetPoline => BMFPolyline(coordinates: [BMFCoordinate(0.0, 0.0),BMFCoordinate(1.0, 1.0)], indexs: [0]);


}
