import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'loc_manage.dart';

class MapOptions {
  static int scanSpan = 4000; //安卓定位间隔
  static BMFCoordinate initCoordinate = BMFCoordinate(30.584355, 114.298572); // wuhan

  ///  坐标类型:国测局坐标gcj02, wgs84,  百度经纬度坐标 bd09ll,
  static String get coor_type => initAndroidOptions().coordType.toString().split('.').last;
  /// 当前位置图层数据。用于更新当前位置提供参数。
  static BMFUserLocation get userLocation {
    BMFLocation location = BMFLocation(coordinate: LocManage.loc);
    BMFUserLocation userLocation = BMFUserLocation(location: location);
    return userLocation;
  }

  /// 设置地图参数
  static BMFMapOptions initMapOptions({int zoomLevel = 18, bool scrollEnabled = true, showZoomControl = false, BMFCoordinate? center, String? channel, BMFEdgeInsets? mapPadding}) {
    // dao.url
    BMFMapOptions mapOptions = BMFMapOptions(
      zoomLevel: zoomLevel,
      minZoomLevel: 1,
      maxZoomLevel: 22,
      showZoomControl: showZoomControl,
      showMapScaleBar: true,
      overlookEnabled: false,
      scrollEnabled: scrollEnabled,
      // mapScaleBarPosition: BMFPoint(10.r, Get.size.height - Get.bottomBarHeight *2),
      logoPosition: channel == 'oppo' ? BMFLogoPosition.LeftBottom : BMFLogoPosition.LeftBottom,
      mapPadding: mapPadding ?? BMFEdgeInsets(top: 0, left: 0, right: 0, bottom: 0),
      center: center ?? LocManage.loc,
    );
    return mapOptions;
  }

  /// 设置地图参数
  static BaiduLocationAndroidOption initAndroidOptions() {
    BaiduLocationAndroidOption options = BaiduLocationAndroidOption(
      locationMode: BMFLocationMode.hightAccuracy,
      locationPurpose: BMFLocationPurpose.sport,
      isNeedAddress: true,
      isNeedAltitude: true,
      isNeedLocationPoiList: true,
      isNeedNewVersionRgc: true,
      isNeedLocationDescribe: true,
      openGps: true,
      scanspan: scanSpan,
      coordType: BMFLocationCoordType.bd09ll,
    );
    return options;
  }

  static BaiduLocationIOSOption initIOSOptions({bool allowsBackgroundLocationUpdates = false}) {
    BaiduLocationIOSOption options = BaiduLocationIOSOption(
      locationTimeout: 20,
      reGeocodeTimeout: 20,
      distanceFilter: 3,
      activityType: BMFActivityType.automotiveNavigation,
      isNeedNewVersionRgc: true,
      coordType: BMFLocationCoordType.bd09ll,
      desiredAccuracy: BMFDesiredAccuracy.best,
      allowsBackgroundLocationUpdates: allowsBackgroundLocationUpdates,
      pausesLocationUpdatesAutomatically: false,
    );
    return options;
  }
}
