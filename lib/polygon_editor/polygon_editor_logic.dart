import 'package:app_kit/core/app_define.dart';
import 'package:app_log/app_log.dart';
import 'package:get/get.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../generated/assets.dart';
import '../map_small/map_small_logic.dart'; // 适配库
import '../utils/ast_tool_map.dart';

enum PointType {
  vertex, // 实点（多边形的实际顶点）
  midpoint, // 虚点（辅助生成的中间操作点）
}

class EditPoint {
  String id;
  BMFCoordinate coordinate;
  PointType type;

  EditPoint({required this.id, required this.coordinate, required this.type});
}

PolygonEditorLogic get cPolE => Get.isRegistered<PolygonEditorLogic>()
    ? Get.find<PolygonEditorLogic>()
    : Get.put<PolygonEditorLogic>(PolygonEditorLogic());

class PolygonEditorLogic extends GetxController {
  // 核心数据源
  var editPoints = <EditPoint>[].obs;

  // 用于更新地图上的 Markers
  var mapMarkers = <BMFMarker>[].obs;

  /// 定义两种图标路径（根据你的项目资源修改）
  String kIconLinear = AstToolMap.pkgAst(
    AstMap.lib_ast_images_map_act_line0,
  ); // 在直线上的图标
  String kIconVertex = AstToolMap.pkgAst(
    AstMap.lib_ast_images_loc_dtz_red,
  ); // 拐点图标
  double scaleXy = 1.0;

  /// 初始化：只有 A 和 C，自动生成 B
  void initPoints(BMFCoordinate pointA, BMFCoordinate pointC) {
    // 1. 创建实点 A
    var pA = EditPoint(id: 'A', coordinate: pointA, type: PointType.vertex);
    // 2. 创建实点 C
    var pC = EditPoint(id: 'C', coordinate: pointC, type: PointType.vertex);

    // 3. 计算中间虚点 B
    var coordB = _calculateMidPoint(pointA, pointC);
    var pB = EditPoint(id: 'B', coordinate: coordB, type: PointType.midpoint);

    editPoints.value = [pA, pB, pC];
    refreshMarkers();
  }

  /// 核心算法：处理拖拽结束
  void onMarkerDragEnd(BMFMarker marker, BMFCoordinate newPosition) {
    // 找到对应的点索引
    int index = editPoints.indexWhere((p) {
      logs('--p.id--:${p.id}--marker.identifier--:${marker.customMap?["id"]}');
      return p.id == marker.customMap?['id'];
    });
    logs('--index--:$index');
    if (index == -1) return;

    EditPoint currentPoint = editPoints[index];

    // 更新当前拖动点的位置
    currentPoint.coordinate = newPosition;

    // === 关键逻辑：如果是虚点被拖动，裂变生成新点 ===
    if (currentPoint.type == PointType.midpoint) {
      // 1. 晋升：将当前虚点(B)变为实点
      currentPoint.type = PointType.vertex;
      // 可选：给它改个名字或ID，这里为了演示保留原ID

      // 2. 获取左侧实点 (A) 和 右侧实点 (C)
      // 注意：数组结构此时是 [A, B(当前), C]
      // 这里的 index 就是 B 的位置

      // 3. 在左侧 (A和B之间) 插入新虚点 B1
      if (index > 0) {
        var prevPoint = editPoints[index - 1];
        var midCoord1 = _calculateMidPoint(
          prevPoint.coordinate,
          currentPoint.coordinate,
        );
        var pB1 = EditPoint(
          id: '${currentPoint.id}_left_${DateTime.now().millisecondsSinceEpoch}',
          coordinate: midCoord1,
          type: PointType.midpoint,
        );
        editPoints.insert(index, pB1);
        // 插入后，当前点 B 的索引加 1 了
        index++;
      }

      // 4. 在右侧 (B和C之间) 插入新虚点 B2
      if (index < editPoints.length - 1) {
        var nextPoint = editPoints[index + 1];
        var midCoord2 = _calculateMidPoint(
          currentPoint.coordinate,
          nextPoint.coordinate,
        );
        var pB2 = EditPoint(
          id: '${currentPoint.id}_right_${DateTime.now().millisecondsSinceEpoch}',
          coordinate: midCoord2,
          type: PointType.midpoint,
        );
        editPoints.insert(index + 1, pB2);
      }
    } else {
      // === 如果是实点(A或C)被拖动 ===
      // 需要更新它左右两侧的虚点位置，保持虚点永远在直线中间
      _updateAdjacentMidpoints(index);
    }

    refreshMarkers();
  }

  /// 辅助：更新实点旁边的虚点位置
  void _updateAdjacentMidpoints(int index) {
    // 检查左边是否有虚点，有则重新计算位置
    if (index > 0 && editPoints[index - 1].type == PointType.midpoint) {
      // 左边的虚点需要在 (index-2) 和 (index) 之间
      if (index >= 2) {
        editPoints[index - 1].coordinate = _calculateMidPoint(
          editPoints[index - 2].coordinate,
          editPoints[index].coordinate,
        );
      }
    }
    // 检查右边是否有虚点
    if (index < editPoints.length - 1 &&
        editPoints[index + 1].type == PointType.midpoint) {
      // 右边的虚点需要在 (index) 和 (index+2) 之间
      if (index + 2 < editPoints.length) {
        editPoints[index + 1].coordinate = _calculateMidPoint(
          editPoints[index].coordinate,
          editPoints[index + 2].coordinate,
        );
      }
    }
  }

  /// 基础算法：计算两点中心
  BMFCoordinate _calculateMidPoint(BMFCoordinate p1, BMFCoordinate p2) {
    return BMFCoordinate(
      (p1.latitude + p2.latitude) / 2,
      (p1.longitude + p2.longitude) / 2,
    );
  }

  /// UI渲染：将数据转换为百度的 BMFMarker
  void refreshMarkers() {
    List<BMFMarker> newMarkers = [];
    for (var point in editPoints) {
      // 根据类型区分图标
      String iconPath = point.type == PointType.vertex
          ? kIconVertex // 实心点图标
          : kIconLinear; // 空心点/半透明图标

      var marker = BMFMarker.icon(
        position: point.coordinate,
        icon: iconPath,
        customMap: {'id': point.id},
        draggable: true, // 必须可拖拽
        // 使用 .r 进行尺寸适配
        scaleX: scaleXy, // 图片本身大小如果不合适，也可以用 .r 算好宽高生成 bitmap
        scaleY: scaleXy,
        centerOffset: BMFPoint(0, point.type == PointType.vertex ? (inAndroid?3.r:-10.r): (inAndroid?20.r:0)),
      );

      newMarkers.add(marker);
    }
    if (mapMarkers.isNotEmpty) cMs.kmap?.removeMarkers(mapMarkers);
    mapMarkers.value = newMarkers;
    logs('--mapMarkers.value--:${mapMarkers.toList()}');
    cMs.update_mkPolygons();

    // 这里你需要调用百度地图控制器的 update 或 add markers 方法
    cMs.kmap?.addMarkers(newMarkers);
    // myMapController.cleanAllMarkers();
    // myMapController.addMarkers(newMarkers);
  }
}
