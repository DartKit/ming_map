import 'package:app_kit/core/kt_export.dart';
import 'package:app_kit/widgets/kit_views/kit_view.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:geolocator/geolocator.dart';

class MapTool {
  static Future<bool> isLocationServiceEnabled() async {
    var isOpen = await Geolocator.isLocationServiceEnabled();
    logs('---isOpen-1-$isOpen');
    if (isOpen == false) {
      KitView.alert(
          alignment: Alignment.center,
          content: '当前业务需您先开启手机定位功能！\n\n步骤：\n下滑通知栏->找到定位图标->点击打开',
          cancel: () {},
          sureName: '开启权限',
          sure: () {
            openSetting();
          });
    }
    return isOpen;
  }

  static Future<void> openSetting() async {
    Geolocator.openLocationSettings();
  }

  /// 判断三个经纬度点是否在一条直线上
  /// [precision] 精度阈值，越小要求越精确。默认 1e-9。
  static bool arePointsCollinear(
      BMFCoordinate p1,
      BMFCoordinate p2,
      BMFCoordinate p3, {
        double precision = 1e-9,
      }) {
    // 1. 提取坐标，减少多次访问对象的开销
    final double x1 = p1.longitude;
    final double y1 = p1.latitude;
    final double x2 = p2.longitude;
    final double y2 = p2.latitude;
    final double x3 = p3.longitude;
    final double y3 = p3.latitude;

    // 2. 计算向量 AB (x2-x1, y2-y1) 和向量 AC (x3-x1, y3-y1)
    // 3. 计算二维叉积: (x2 - x1) * (y3 - y1) - (y2 - y1) * (x3 - x1)
    final double crossProduct = (x2 - x1) * (y3 - y1) - (y2 - y1) * (x3 - x1);

    // 4. 如果叉积接近 0，则三点共线
    return crossProduct.abs() < precision;
  }
}