import 'package:app_kit/https/kit_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:ming_map/generated/assets.dart';
import '../loc_manage.dart';
import '../polygon_editor/polygon_editor_logic.dart';
import '../utils/ast_tool_map.dart';
import 'marker_mo.dart';
import 'package:get/get.dart';

MapSmallLogic get cMs => Get.isRegistered<MapSmallLogic>() ? Get.find<MapSmallLogic>() : Get.put<MapSmallLogic>(MapSmallLogic());

enum ActType {
  none('无', 'none'),
  marker('点位', 'marker', AstMap.lib_ast_images_act_maker),
  polyline('线段', 'polyline', AstMap.lib_ast_images_act_line),
  polygon('多边形', 'polygon', AstMap.lib_ast_images_act_pol);

  const ActType(this.name, this.value, [this._rawIcon = '']);
  final String name;
  final String value;
  final String _rawIcon;

  String get icon => _rawIcon.isEmpty ? '' : AstToolMap.pkgAst(_rawIcon);

  static ActType type(String value) => ActType.values.firstWhereOrNull((e) => e.value == value) ?? ActType.none;
}

class MapSmallLogic extends GetxController {
  BMFMapController? kmap;
  BMFMarker? mkSelf; // 点我修改位置生成的大头针
  BMFMarker? selMarker; // 选中的Marker
  var mkMosInMap = <BMFMarker>[].obs; // 地图已经展示的Markers
  var mkMos = <MarkerMo>[].obs;
  var mkMoSel = MarkerMo().obs;
  // var showLocManual = false.obs; // 展示“点我修改位置”
  final _actType = (ActType.none).obs; // 选择交互类型，点线面

  var isLocManual = false.obs; // 已经点击了“点我修改位置”，改为手动选择位置
  var mkSelIcon = AstToolMap.pkgAst(AstMap.lib_ast_images_tree_xd0); // 选中Marker的图标
  var mkDefIcon = AstToolMap.pkgAst(AstMap.lib_ast_images_tree_xd1); // Marker默认的图标
  var tip = ''.obs; // 地图顶部额外的提示文案
  var zIndex = 1000;
  double scaleXy = 2.0;
  var locTip = '定位中...'.obs; // 外部只读。地图页面读写

  var okCoord = BMFCoordinate(0, 0).obs; // isLocManual.isTrue 时 mkSelf 位置，isLocManual.isFalse 时 实时定位的位置

  // var setPolygon = false.obs; // 设置多边形
  // var mkPolygons = <BMFMarker>[].obs;
  BMFPolygon? act_polygon;

  var showMeView = true.obs;

  // void setMkMos(List<MarkerMo> mos,{MarkerMo? autoSel}) {
  //    _mkMos.value = mos;
  //  }

  // set mkMos(List<MarkerMo> mos) {
  //   _mkMos.value = mos;
  // }
  /// 添加编辑点线面时候对应的点位
  List<BMFCoordinate> act_points (){
    switch (actType) {
      case ActType.marker:
        {
          return (isLocManual.isTrue )? [cMs.okCoord.value] : [LocManage.loc];
        }
      case ActType.polyline:
        {
          // TODO
          return [];
        }
      case ActType.polygon:
        {
          return cPolE.editPoints.map((e) {
            return e.coordinate;
          }).toList();
        }
      case ActType.none:
        return [];
    }
  }

  set actType(ActType v) {
    _actType.value = v;
    switch (actType) {
      case ActType.marker:
        {
          cMs.kmap?.removeMarkers(cPolE.mapMarkers);
          cPolE.mapMarkers.clear();
          if (act_polygon != null) {
            cMs.kmap?.removeOverlay(cMs.act_polygon!.id);
            cMs.act_polygon = null;
          }
        }
        break;
      case ActType.polygon:
        {
          if (act_polygon != null) {
            cMs.kmap?.removeOverlay(cMs.act_polygon!.id);
            cMs.act_polygon = null;
          }
          if (cMs.mkSelf != null) {
            cMs.kmap?.removeMarker(cMs.mkSelf!);
            cMs.mkSelf = null;
          }
        }
        break;
      case ActType.polyline:
        {
          // locTip.value = '绘制线路中...';
        }
        break;
      default:
        {}
    }
  }

  ActType get actType => _actType.value;

  void set_polygon() {
    _actType.value = ActType.polygon;
    // mkPolygons.clear();
    // showLocManual.value = false;
  }

  Future<void> setHideLocManual() async {
    cMs.actType = ActType.none;
    cMs.isLocManual.value = false;
    if (cMs.mkSelf != null) {
      kmap?.removeMarker(cMs.mkSelf!);
      cMs.mkSelf = null;
    }
  }

  Future<void> toCenter({BMFCoordinate? coordinate, double toZoom = 0}) async {
    cMs.kmap?.setCenterCoordinate(coordinate ?? LocManage.loc, true);
    if (toZoom > 0) cMs.kmap?.setZoomTo(toZoom);
  }

  BMFUserLocation get userLocation {
    BMFLocation location = BMFLocation(coordinate: LocManage.loc);
    BMFUserLocation userLocation = BMFUserLocation(location: location);
    return userLocation;
  }

  void update_mkPolygons() {
    // logs('--cPolE.mapMarkers.length--:${cPolE.mapMarkers.length}');
    if ((cPolE.mapMarkers.length >= 3)) {
      List<BMFCoordinate> coordinates = cPolE.mapMarkers.map((e) => e.position).toList();
      if (cMs.act_polygon == null) {
        cMs.act_polygon = BMFPolygon(coordinates: coordinates, fillColor: Colors.blue.withValues(alpha: 0.2), width: 2);
        cMs.kmap?.addPolygon(cMs.act_polygon!);
      } else {
        cMs.act_polygon!.updateCoordinates(coordinates);
      }
    }
  }

  // void updateMarkerIcons() {
  //   if (mkPolygons.length < 3) return;
  //
  //   for (int i = 0; i < mkPolygons.length; i++) {
  //     // 1. 获取当前点、左邻点、右邻点 (处理闭合回路的索引)
  //     BMFMarker current = mkPolygons[i];
  //     BMFMarker prev = mkPolygons[(i - 1 + mkPolygons.length) % mkPolygons.length];
  //     BMFMarker next = mkPolygons[(i + 1) % mkPolygons.length];
  //
  //     // 2. 调用叉积算法判断是否共线
  //     bool isCollinear = _checkCollinear(
  //       prev.position,
  //       current.position,
  //       next.position,
  //     );
  //
  //     // 3. 根据判断结果更新图标
  //     // 注意：百度地图 SDK 中修改 icon 后需要重新赋值或调用 update 方法
  //     String targetIcon = isCollinear ? kIconLinear : kIconVertex;
  //
  //     if (current.icon != targetIcon) {
  //       current.updateIcon(targetIcon);
  //     }
  //   }
  // }
  //
  // /// 高性能共线检查 (基于前述向量叉积算法)
  // bool _checkCollinear(BMFCoordinate p1, BMFCoordinate p2, BMFCoordinate p3) {
  //   const double precision = 1e-9;
  //   final double val = (p2.longitude - p1.longitude) * (p3.latitude - p1.latitude) -
  //       (p2.latitude - p1.latitude) * (p3.longitude - p1.longitude);
  //   return val.abs() < precision;
  // }

  void reqMarks({required String url, Map<String, dynamic>? map}) async {
    List? res = await KitService.fireGet<List>(url, query: map);
    if (res != null) {
      mkMos.value = List<MarkerMo>.from(
        res.map((e) {
          Map<String, dynamic> map = Map<String, dynamic>.from(e);
          // logs('-map--:${map.runtimeType}--map--:${map}');
          var mo = MarkerMo.fromJson(map);
          // logs('--e--:${e.runtimeType}--e--:${e}');
          mo.map = map;
          return mo;
        }).toList(),
      );
    }
  }
}
