import 'package:app_kit/core/kt_export.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'generated/assets.dart';
import 'utils/ast_tool_map.dart';

class MapLaunch {
  static void sheetOpenMap(
    {
      required  String lat,
      required String lon,
      required String address,
    String exchangePointUrl = '',
  }) {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.0),
          topRight: Radius.circular(10.0),
        ),
      ),
      context: Get.context!,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Image(
                  image: AssetImage(
                    AstToolMap.pkgAst(AstMap.lib_ast_images_faviconbd),
                  ),
                  width: 24.0,
                ),
                title: const Text("使用百度地图打开"),
                onTap: () async {
                  Navigator.pop(context);
                  _gotoMap(
                    1,
                    lat,
                    lon,
                    address,
                    exchangePointUrl: exchangePointUrl,
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Image(
                  image: AssetImage(
                    AstToolMap.pkgAst(AstMap.lib_ast_images_favicongd),
                  ),
                  width: 24.0,
                ),
                title: const Text("使用高德地图打开"),
                onTap: () async {
                  Navigator.pop(context);
                  _gotoMap(
                    2,
                    lat,
                    lon,
                    address,
                    exchangePointUrl: exchangePointUrl,
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Image(
                  image: AssetImage(
                    AstToolMap.pkgAst(AstMap.lib_ast_images_favicontx),
                  ),
                  width: 24.0,
                ),
                title: const Text("使用腾讯地图打开"),
                onTap: () async {
                  Navigator.pop(context);
                  _gotoMap(
                    3,
                    lat,
                    lon,
                    address,
                    exchangePointUrl: exchangePointUrl,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<bool> _gotoMap(
    type,
    String lat,
    String lon,
    String address, {
    String exchangePointUrl = '',
  }) async {
    String url = '';
    logs('--0-lat--$lat---lon--$lon');
    if ((exchangePointUrl.isNotEmpty) &&
        (type != 1) &&
        lat.isNotEmpty &&
        lon.isNotEmpty) {
      Map<String, dynamic> map = {'latitude': lat, 'longitude': lon};
      Map? res = await KitService.fire<Map>(exchangePointUrl, query: map);
      if (res != null) {
        if (res.containsKey('longitude')) lon = res['longitude'];
        if (res.containsKey('latitude')) lat = res['latitude'];
        if (res.containsKey('lon')) lon = res['lon'];
        if (res.containsKey('lat')) lat = res['lat'];
      }
    }
    switch (type) {
      case 2:
        {
          // 高德
          url =
              'amapuri://route/plan/?dlat=$lat&dlon=$lon&dname=${Uri.encodeComponent(address)}&dev=0&t=0';
          if (lat.isEmpty) {
            url =
                'amapuri://route/plan/?dname=${Uri.encodeComponent(address)}&dev=0&t=0';
          }
          break;
        }
      case 3:
        {
          // QQ腾讯地图
          url =
              'qqmap://map/routeplan?type=drive&fromcoord=CurrentLocation&tocoord=$lat,$lon&to=${Uri.encodeComponent(address)}&referer=S5WBZ-J2IK3-DFV3F-YGWKD-6MUZV-FFFEH';
          if (lat.isEmpty) {
            url =
                'qqmap://map/routeplan?type=drive&fromcoord=CurrentLocation&to=${Uri.encodeComponent(address)}&referer=S5WBZ-J2IK3-DFV3F-YGWKD-6MUZV-FFFEH';
          }

          break;
        }
      default: // 其他是百度
        // url = 'baidumap://map/direction?destination=latlng:${lat},${lon}&coord_type=bd09ll&mode=driving';
        url =
            'baidumap://map/direction?destination=$lat,$lon&coord_type=bd09ll&mode=driving';
        if (lat.isEmpty) {
          url =
              'baidumap://map/direction?destination=$address&coord_type=bd09ll&mode=driving';
        }
    }
    logs('--url----:$url');
    bool can = await canLaunchUrlString(url);
    if (!can) {
      switch (type) {
        case 2:
          kPopSnack('请安装高德地图');
          break;
        case 3:
          kPopSnack('请安装腾讯地图');
          break;
        default:
          kPopSnack('请安装百度地图');
      }
      return false;
    }
    await launchUrlString(url);
    return can;
  }
}
