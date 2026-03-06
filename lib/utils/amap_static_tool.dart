import 'dart:math';

import 'package:app_kit/core/app_log.dart';
import 'package:app_kit/extension/string_add.dart';

class AMapStaticTool {
  /// 生成高德静态地图 URL
  ///
  /// [pointData] 入参数据，包含 type 和 points
  /// [width] 图片宽度
  /// [height] 图片高度
  /// [key] 高德地图 Key
  static String getStaticMapUrl({
    required Map<String, dynamic> pointData,
    int width = 750,
    int height = 400,
    String key = 'ee95e52bf08006f63fd29bcfbcf21df0', // 默认使用示例Key，实际使用请替换
  }) {
    final String type = pointData['type'] ?? 'marker';
    final List<dynamic> pointsRaw = pointData['points'] ?? [];

    // 转换点位数据
    List<Map<String, String>> points = [];
    for (var p in pointsRaw) {
      if (p is Map) {
        points.add({
          'lat': (p['lat'].toString()),
          'lng': (p['lng'].toString()),
        });
      }
    }
    // 校验点位数量
    if (points.isEmpty) {
      return ''; // 或者抛出异常
    }
    if ((type == 'polyline' || type == 'line') && points.length < 2) {
      print('Polyline/Line 需要至少 2 个点');
      return '';
    }
    if (type == 'polygon' && points.length < 3) {
      print('Polygon 需要至少 3 个点');
      return '';
    }

    String baseUrl = 'https://restapi.amap.com/v3/staticmap';
    String params = 'size=$width*$height&key=$key';

    // 逻辑分支
    if (type == 'marker') {
      // Marker 逻辑：缩放 11，中心点为最后一个点
      final center = points.last;
      String location = '${center['lng']},${center['lat']}';
      params += '&location=$location&zoom=15';
      params +=
      '&markers=-1,https://whsdzn-files.oss-cn-beijing.aliyuncs.com/v2oss//tree_gs2.png,0:$location';
    } else {
      // Polygon 或 Polyline 逻辑

      // 1. 计算中心点和缩放级别
      final bounds = _getBounds(points);
      final center = _getCenter(bounds);

      // 预留边距，比如 15%
      // 计算 Zoom
      int zoom = _calculateZoom(bounds, width, height, paddingFactor: 0.15);

      params += '&location=${center['lng']},${center['lat']}';
      params += '&zoom=$zoom';

      // 3. 拼接 paths 参数
      // 检查点数量，如果过多则进行抽稀
      // 浏览器 URL 限制通常在 2KB 左右，建议控制点数在 80-100 以内
      if (points.length > 80) {
        points = _thinPoints(points, maxCount: 80);
      }

      // 格式：width, color, alpha, fillColor, fillAlpha : lng,lat;lng,lat...
      // 颜色需要去掉 #，例如 0xFF0000
      String pathStyle = '';
      if (type == 'polygon') {
        // 多边形样式：边框宽2，红色，不透明，填充绿色，0.15透明
        pathStyle = '2,0xFF0000,1,0x008000,0.15';
      } else {
        // 线样式：宽5，蓝色，不透明
        pathStyle = '5,0x0000FF,1,,';
      }

      String coords = points.map((p) => '${p['lng']},${p['lat']}').join(';');
      // 如果是多边形，确保首尾相连（高德API其实不强制，但闭合更稳妥）
      if (type == 'polygon' && points.isNotEmpty) {
        final first = points.first;
        final last = points.last;
        if (first['lat'] != last['lat'] || first['lng'] != last['lng']) {
          coords += ';${first['lng']},${first['lat']}';
        }
      }

      params += '&paths=$pathStyle:$coords';
    }

    // 拼接完整 URL 并返回
    var url = '$baseUrl?$params';
    logs('url: $url');
    return url;
  }

  /// 抽稀点位，使用均匀采样
  static List<Map<String, String>> _thinPoints(
      List<Map<String, String>> points, {
        int maxCount = 80,
      }) {
    if (points.length <= maxCount) return points;

    List<Map<String, String>> thinned = [];
    // 保留起点
    thinned.add(points.first);

    // 中间点均匀采样
    // 我们需要再选 maxCount - 2 个点
    // 步长 step = (total - 2) / (maxCount - 2)
    int countToKeep = maxCount - 2;
    // 实际中间可用的点数
    int availableMiddlePoints = points.length - 2;

    // 如果需要的点比中间的可选点还多，理论上不会发生，因为前面 check 了 length
    double step = availableMiddlePoints / countToKeep;

    for (int i = 1; i <= countToKeep; i++) {
      int index = 1 + (i * step).toInt();
      if (index < points.length - 1) {
        thinned.add(points[index]);
      }
    }

    // 保留终点
    thinned.add(points.last);

    return thinned;
  }

  /// 计算边界
  static Map<String, double> _getBounds(List<Map<String, String>> points) {
    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (var p in points) {
      if (p['lat']!.toDouble < minLat) minLat = p['lat']!.toDouble;
      if (p['lat']!.toDouble > maxLat) maxLat = p['lat']!.toDouble;
      if (p['lng']!.toDouble < minLng) minLng = p['lng']!.toDouble;
      if (p['lng']!.toDouble > maxLng) maxLng = p['lng']!.toDouble;
    }
    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }

  /// 计算中心点
  static Map<String, double> _getCenter(Map<String, double> bounds) {
    return {
      'lat': (bounds['minLat']! + bounds['maxLat']!) / 2,
      'lng': (bounds['minLng']! + bounds['maxLng']!) / 2,
    };
  }

  /// 计算缩放级别
  static int _calculateZoom(
      Map<String, double> bounds,
      int mapWidth,
      int mapHeight, {
        double paddingFactor = 0.1,
      }) {
    // 实际可用区域
    double viewWidth = mapWidth * (1 - paddingFactor * 2);
    double viewHeight = mapHeight * (1 - paddingFactor * 2);

    double latSpan = bounds['maxLat']! - bounds['minLat']!;
    double lngSpan = bounds['maxLng']! - bounds['minLng']!;

    if (latSpan == 0 && lngSpan == 0) return 15; // 单点情况

    // 经度计算 (360度 / 256像素 * 2^zoom)
    // viewWidth / 256 = (lngSpan / 360) * 2^zoom
    // 2^zoom = (viewWidth / 256) * (360 / lngSpan)
    double zoomLng = log((viewWidth / 256) * (360 / lngSpan)) / log(2);

    // 纬度计算 (简化版，Web Mercator 纬度非线性，但在小范围可近似或取保守值)
    // 简单估算：每度约为 111km -> 111000米
    // 高德最大分辨率约为 156543m/pixel (zoom 0)
    // 2^zoom = (viewHeight / 256) * (180 / latSpan) -- 这是一个非常粗略的估算，更精确应该用 Mercator

    // 使用更常用的 Web Mercator 适配公式:
    // Resolution = 156543.03392 * cos(lat) / 2^zoom (meters/pixel)
    // Distance = latSpan * 111319 (meters, approx near equator, but changes)

    // 我们用一个更简单的经验公式（类似 Google Maps）
    // zoom = log2(360 * width / 256 / lngSpan)

    // 为了保险，我们取经度和纬度计算出的最小 Zoom
    // 纬度方向稍微复杂，这里采用一个经验比例：经度跨度 vs 纬度跨度
    // 或者直接使用经度作为主要参考，因为通常屏幕是宽屏，且纬度变化导致的变形在高 zoom 下可忽略

    // double zoom = zoomLng; // unused

    // 校验纬度能否放下
    // 如果是高瘦的多边形，经度 zoom 会很大，导致高度放不下
    // 简单检查长宽比
    // 1 lat deg ~= 1 lng deg (at equator). At lat 40, 1 lng deg ~= 0.76 lat deg meters
    // Ratio = height / width
    // BoundsRatio = latSpan / lngSpan
    // 如果 BoundsRatio > Ratio, 说明高度是瓶颈

    // 为了更准确，我们可以分别算。
    // LatZoom:
    // visual_angle = latSpan
    // viewHeightPixels / 256 = (latSpan / 180) * 2^z (Very rough)
    // better: 2^z = viewHeight * 360 / (latSpan * 256 * 2) (Approx 2x factor maybe?)

    // 让我们用最稳妥的迭代法或者库公式。但在没库的情况下，使用“最大跨度”法。
    // 确定每个像素代表的度数。
    // GLOBAL_PX_PER_DEG_LNG = 256 / 360 * 2^zoom

    // 目标: lngSpan * GLOBAL_PX_PER_DEG_LNG <= viewWidth
    // lngSpan * (256/360) * 2^zoom <= viewWidth
    // 2^zoom <= viewWidth * 360 / (lngSpan * 256)

    // 同理 Lat: latSpan * (256/180) * 2^zoom <= viewHeight (Roughly)
    double zoomLat = log((viewHeight / 256) * (180 / latSpan)) / log(2);

    return min(zoomLng, zoomLat).floor().clamp(1, 17);
  }
}
