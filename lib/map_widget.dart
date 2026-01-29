import 'package:app_kit/core/kt_export.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';

import 'map_options.dart';

typedef MapCallback = Function(BMFMapController controller);


class MapWidget extends StatefulWidget {
  /// 创建MapWidget回调
  final MapCallback? onMapDidLoad;
  const MapWidget({super.key, this.onMapDidLoad});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late BMFMapController myMapVc;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.white, child: _createMap());
  }

  Widget _createMap() {
    return BMFMapWidget(
      onBMFMapCreated: (controller) {
        _onBMFMapCreated(controller);
      },
      mapOptions: MapOptions.initMapOptions(),
    );
  }

  /// 创建完成回调
  void _onBMFMapCreated(BMFMapController controller) {
    myMapVc = controller;
    // MapManage.mapVc = myMapVc;
    controller.showUserLocation(true);
    controller.setMapDidLoadCallback(callback: () async {
      logs('mapDidLoad-地图加载完成');
      if (widget.onMapDidLoad != null) {
        widget.onMapDidLoad!(controller);
      }
      // BMFCustomMapStyleOption customMapStyleOption = BMFCustomMapStyleOption(
      //   customMapStyleID: "bddda1fe639f2e81d86030601e0936d1",
      //   customMapStyleFilePath: 'file/map16c2b330a32ee287fe8dd4ab25efdd79.sty',
      // );
      // myMapVc.setCustomMapStyle('file/map16c2b330a32ee287fe8dd4ab25efdd79.sty', 0);
      // myMapVc.setCustomMapStyleWithOptionPath(
      //     customMapStyleOption: customMapStyleOption,
      //     preload: (String? path) {
      //       logs('preload');
      //     },
      //     success: (String? path) {
      //       logs('success');
      //     },
      //     error: (int? errorCode, String? path) {
      //       logs('error');
      //     });


    });
  }
}
