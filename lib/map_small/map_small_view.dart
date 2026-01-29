import 'dart:async';
import 'package:app_kit/core/app_colors.dart';
import 'package:app_kit/core/app_define.dart';
import 'package:app_kit/extension/string_add.dart';
import 'package:app_kit/widgets/kit_views/kit_view.dart';
import 'package:app_kit/widgets/text.dart';
import 'package:app_log/app_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import '../generated/assets.dart';
import '../loc_manage.dart';
import '../map_container.dart';
import '../map_options.dart';
import '../polygon_editor/polygon_editor_logic.dart';
import '../utils/ast_tool_map.dart';
import '../views/btn_clear_polygon.dart';
import '../views/btn_hide_location.dart';
import '../views/btn_my_location.dart';
import 'map_small_logic.dart';
import 'package:dio_log/dio_log.dart';

import 'marker_mo.dart';

class MapSmall extends StatefulWidget {
  const MapSmall({
    super.key,
    this.longitude = '', // 初始化中心点经度
    this.latitude = '', // 初始化中心点纬度
    this.address = '', // 初始化中心点地址-内部暂时未使用
    this.locToMe = false, // 定位到自己当前位置
    this.fireLoc = false, // 地图初始化就定位
    this.mapHeight, // 地图高度
    this.callLocFirst, // 地图初始化定位成功后回调
    this.margin, // 容器边距
    // this.push = false,
  });

  final bool locToMe;
  final bool fireLoc;
  final String longitude;
  final String latitude;
  final String address;
  final double? mapHeight;
  final EdgeInsets? margin;
  // final bool push;
  final Function({required String lat, required String lon, String? adr})? callLocFirst;

  @override
  State<MapSmall> createState() => _MapSmallState();
}

class _MapSmallState extends State<MapSmall> {
  List<StreamSubscription> _listens = [];
  bool setCenter = false;
  var hasCallLocFirst = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 100), () {
      _addListener();
    });
    Future.delayed(Duration(milliseconds: 10000), () {
      cMs.showMeView.value = widget.locToMe;
      if (widget.fireLoc && cMs.locTip.startsWith('定位中')) {
        cMs.locTip.value += ' 如果很长时间未获取到定位可能是手机定位模块异常，一般重启手机可恢复！';
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    cMs.actType = ActType.none;
    for (var o in _listens) {
      o.cancel();
    }
  }

  void _addListener() {
    _listens = [
      LocManage().locRes.listen((p0) {
        logs(
          '--LocManage.loc-1-latitude-:${klocRes.latitude}--klocRes.longitude--:${klocRes.longitude}',
        );
        if (cMs.locTip.isNotEmpty) cMs.locTip.value = '';
        if ((widget.callLocFirst != null) &&
            (cMs.kmap != null) &&
            (hasCallLocFirst == false)) {
          widget.callLocFirst!(
            lat: p0.latitude.toString(),
            lon: p0.longitude.toString(),
            adr: p0.address.toString(),
          );
          hasCallLocFirst = true;
        }
        if ((widget.locToMe) && (setCenter == false)) {
          cMs.kmap?.setCenterCoordinate(LocManage.loc, true);
          setCenter = true;
        }
        // logs('--cMapt.userLocation--:${cMs.userLocation.toMap()}');
        if (cMs.showMeView.isTrue) {
          cMs.kmap?.updateLocationData(cMs.userLocation).then((x) {
            // logs('-ff-x--:${x}');
          });
        }
        if (cMs.isLocManual.isFalse)
          cMs.okCoord.value = BMFCoordinate(
            p0.latitude ?? 0,
            p0.longitude ?? 0,
          );
      }),
      cMs.mkMos.listen((p0) {
        logs('--po--:${p0.toString()}');
        cMs.mkMoSel.value = MarkerMo();
        _addMarkers();
        // _add_fence_list(p0);
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width,
      height: widget.mapHeight ?? Get.width,
      child: MapContainer(
        margin: widget.margin,
        tops: [
          Obx(() {
            if (cMs.tip.isEmpty) return SizedBox();
            return Center(child: InfoTxt(cMs.tip.value));
          }),
          if (widget.fireLoc)
            Obx(() {
              if (cMs.locTip.isEmpty) return SizedBox();
              return Center(child: InfoTxt(cMs.locTip.value));
            }),
        ],
        rights: [
          MyLocation(
            onTap: ({required BMFCoordinate coo}) {
              if (cMs.kmap != null) cMs.kmap?.setCenterCoordinate(coo, true);
            },
          ),
          HideLocation(),
          BtnClearPolygon(),
        ],
        bottoms: [
          Obx(() {
            if (cMs.actType == ActType.none) return SizedBox();
            return Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 2.r),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  gradient: LinearGradient(
                    //渐变位置
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 1.0],
                    colors: const [Color(0xFFFFF1E3), Color(0xFFFFEFD7)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(.0, 0),
                      blurRadius: 2.0,
                      color: CC.line,
                    ),
                  ],
                ),
                constraints: BoxConstraints(
                  minHeight: cMs.actType == ActType.marker ? 40.r : 34.r,
                ),
                child: Obx(() {
                  return Row(
                    spacing: 10.r,
                    children: [
                      if ((cMs.actType == ActType.marker) &&
                          cMs.isLocManual.isFalse)
                        KitView.textTag(
                          '修改位置',
                          callback: () async {
                            cMs.isLocManual.value = !cMs.isLocManual.value;
                            // _marker?.updateDraggable(_locMyself);
                            // _mapController?.updateMapOptions(cMapt.initMapOptions(center: _marker?.position));
                            // if (mounted) setState(() {});
                            logs(
                              '--AstMap.lib_ast_images_loc_dtz_red--:${AstMap.lib_ast_images_loc_dtz_red}',
                            );
                            if (cMs.mkSelf == null) {
                              var st = await cMs.kmap!.getMapStatus();
                              if (st?.targetGeoPt != null) {
                                cMs.mkSelf = BMFMarker.icon(
                                  position: st!.targetGeoPt!,
                                  icon: AstToolMap.pkgAst(
                                    AstMap.lib_ast_images_loc_dtz_red,
                                  ),
                                  draggable: true,
                                  enabled: true,
                                  scaleX: cMs.scaleXy,
                                  scaleY: cMs.scaleXy,
                                  zIndex: (cMs.zIndex++) * 10,
                                );
                              }
                              cMs.kmap!.addMarker(cMs.mkSelf!);
                            }
                          },
                        ),
                      if (cMs.actType == ActType.marker)
                        (MainText(
                          cMs.isLocManual.isFalse
                              ? '定位不准确时请点击左边“修改位置”，\n可以人工指定新位置！'
                              : '长按拖动红色大头针修改位置作为最终数据提交地点！',
                          color: Colors.red,
                          fontSize: 11.r,
                        )),
                      if (cMs.actType == ActType.polygon)
                        (MainText(
                          '初始2点需长按空白处添加，拖动首个方格可新增额外操作点。\n然后拖动大头针和小方格可以编辑围栏区域范围！',
                          color: Colors.red,
                          fontSize: 11.r,
                        )),
                      // if (cMs.mkSelf?.title?.isNotEmpty == true)  Expanded(child: MainText((cMs.mkSelf?.title ?? '') * 1))
                    ],
                  );
                }),
              ),
            );
          }),
        ],
        child: _mapView(),
      ),
    );
  }

  Future<void> _addMarkers() async {
    if (cMs.mkMosInMap.isNotEmpty)
      await cMs.kmap?.removeMarkers(cMs.mkMosInMap);
    cMs.mkMosInMap.clear();

    for (var e in cMs.mkMos) {
      var coo = BMFCoordinate(e.latitude.toDouble, e.longitude.toDouble);
      BMFMarker marker = BMFMarker.icon(
        position: coo,
        identifier: 'small_map_mark',
        icon: e.icon.ifNil(
          AstToolMap.pkgAst(AstMap.lib_ast_images_mk_q_blue),
        ),
        zIndex: cMs.zIndex++,
        enabled: e.can_select,
        scaleX: cMs.scaleXy,
        scaleY: cMs.scaleXy,
        // isOpenCollisionDetection: true,
        // isForceDisplay: false,
        // collisionDetectionPriority: zIndex,
        customMap: e.toJson(),
      );

      if (e.autoSel) {
        marker.updateIcon(cMs.mkSelIcon);
        marker.selected = true;
        cMs.selMarker = marker;
        Future.delayed(Duration(milliseconds: 1000), () {
          cMs.selMarker?.updateZIndex(cMs.zIndex++);
          cMs.mkMoSel.value = e;
        });
      }
      if (cMs.kmap != null) await cMs.kmap?.addMarker(marker);
      cMs.mkMosInMap.add(marker);
    }
  }

  Widget _mapView() {
    return SizedBox(
      child: BMFMapWidget(
        onBMFMapCreated: (controller) {
          _onBMFMapCreated(controller);
        },
        mapOptions: MapOptions.initMapOptions(
          scrollEnabled: true,
          center: (widget.latitude.isNotEmpty || widget.longitude.isNotEmpty)
              ? BMFCoordinate(
                  widget.latitude.toDouble,
                  widget.longitude.toDouble,
                )
              : null,
        ),
      ),
    );
  }

  /// 创建完成回调
  void _onBMFMapCreated(BMFMapController controller) {
    controller.showUserLocation(true);

    cMs.kmap = controller;

    cMs.kmap?.setMapDidLoadCallback(
      callback: () async {
        logs('mapDidLoad-地图加载完成');
        if (widget.fireLoc) LocManage().fireLocation();
      },
    );

    /// 点中底图空白处会回调此接口
    cMs.kmap?.setMapOnClickedMapBlankCallback(
      callback: (BMFCoordinate coordinate) async {
        await _tagClickedReset();
      },
    );

    /// 长按地图时会回调此接口
    cMs.kmap?.setMapOnLongClickCallback(
      callback: (BMFCoordinate coordinate) {
        logs('长按地图时会回调此接口coord=${coordinate.toMap()}');

        if (cMs.actType == ActType.polygon) {
          if (cPolE.mapMarkers.length > 2) return;
          BMFMarker marker = BMFMarker.icon(
            position: coordinate,
            identifier: 'mark_act_polygon',
            icon: cPolE.kIconVertex,
            zIndex: cMs.zIndex++,
            draggable: true,
            customMap: {'id': 'mark_act_polygon'},
            scaleX: cPolE.scaleXy,
            scaleY: cPolE.scaleXy,
          );

          cMs.kmap?.addMarker(marker);
          cPolE.mapMarkers.add(marker);

          if (cPolE.mapMarkers.length == 2) {
            cPolE.initPoints(
              cPolE.mapMarkers.first.position,
              cPolE.mapMarkers.last.position,
            );
          }
        } else {}
      },
    );

    /// 拖拽marker点击回调
    cMs.kmap?.setMapDragMarkerCallback(
      callback:
          (
            BMFMarker marker,
            BMFMarkerDragState newState,
            BMFMarkerDragState oldState,
          ) {
            switch (cMs.actType) {
              case ActType.marker:
                {
                  if (newState == BMFMarkerDragState.Ending) {
                    logs(
                      'MapDragMarker-- marker = ${marker.toMap()}\n newState = ${newState.toString()}\n oldState = ${oldState.toString()}',
                    );
                    cMs.mkSelf = marker;
                    if (cMs.isLocManual.isTrue)
                      cMs.okCoord.value = marker.position;
                  }
                }
                break;
              case ActType.polygon:
                {
                  if (newState == BMFMarkerDragState.Dragging) {
                    for (var m in cPolE.mapMarkers) {
                      if (m.id == marker.id) {
                        m.updatePosition(marker.position);
                      }
                    }

                    cMs.update_mkPolygons();
                  } else if (newState == BMFMarkerDragState.Ending) {
                    logs('--marker--:${marker.toMap()}');
                    cPolE.onMarkerDragEnd(marker, marker.position);
                  }
                }
                break;
              default:
                {}
            }
          },
    );

    /// 地图marker点击回调
    cMs.kmap?.setMapClickedMarkerCallback(
      callback: (BMFMarker marker) async {
        // Map<String,dynamic> map = {};
        // (marker.customMap ?? {}).asMap().entries.map((e) {
        //    return _actionBtn(e.key,e.value);
        // }).toList();

        logs('--marker.customMap--:${marker.customMap}');
        Map<String, dynamic> map = Map<String, dynamic>.from(
          marker.customMap ?? {},
        );
        // logs('--map.runtimeType--:${map.runtimeType}--map--:${map}');
        // logs('--map.map.runtimeType--:${map['map'].runtimeType}--map--:${map['map']}');
        // marker.customMap?['map'] = map;
        logs('--map--:$map');
        var mo = MarkerMo.fromJson(map);
        logs('--mo--:${mo.toJson()}');
        switch (cMs.actType) {
          case ActType.marker:
            {}
            break;
          case ActType.polygon:
            {}
            break;
          default:
            {
              if (cMs.selMarker?.id == marker.id) return;
              await _tagClickedReset();
              bool f = await marker.updateIcon(cMs.mkSelIcon);
              if (f) {
                if (isAndroid) await marker.updateZIndex(cMs.zIndex++);
                Future.delayed(Duration(milliseconds: 200), () {
                  cMs.mkMoSel.value = mo;
                });
                cMs.selMarker = marker;
              }
              logs('--cMs.mkMoSel--:${cMs.mkMoSel.value.toJson()}');
            }
        }
      },
    );
  }

  Future<void> _tagClickedReset() async {
    if (cMs.selMarker != null) {
      // Map<String,dynamic> map = Map<String,dynamic>.from(cMs.selMarker!.customMap?['map'] ?? {});
      // var mo = MarkerMo.fromJson(map);

      logs('--mo.icon--:${cMs.mkMoSel.value.icon}');
      await cMs.selMarker?.updateIcon(cMs.mkDefIcon);
      cMs.selMarker = null;
    }

    cMs.mkMoSel.value = MarkerMo();
  }

  /*
    // if (_lineIndex != null && (_lineIndex?.id != poy_id)) {
    //   await _lineIndex?.updateColors([C.hexToColor(_lineIndex!.customMap!['color']).withOpacity(dao.road_opacity)], indexs: [0]);
    //   _lineIndex = null;
    // }
    // if (_polIndex != null && (_polIndex?.id != poy_id)) {
    //   await _polIndex?.updateStrokeColor(C.hexToColor(_polIndex!.customMap!['color']).withOpacity(dao.road_opacity));
    //   _polIndex = null;
    // }

  Future<void> _newCoordinate(BMFCoordinate coordinate) async {
    Map<String, dynamic> map = coordinate.toMap();
    logs('---map--$map');
    // SdProblemsList? res = await CoService.fire(Url().getPointAddress, params: map);
    // if (res?.address != null) {
    //   // await cMs.kmap?.removeMarker(_marker!);
    //   await _addMarkersLoc(locCo: coordinate, address: res?.address);
    //   widget.call(coordinate.latitude.toString(), coordinate.longitude.toString(), res?.address ?? '');
    // }
  }

  Future<void> _addMarkersLoc({BMFCoordinate? locCo, String? address}) async {
    BMFCoordinate co = LocManage.loc;
    String? title = address ?? (widget.address.isNotEmpty ? widget.address : klocRes.locationDetail);
    logs('--address--:$address--klocRes.locationDetail--:${klocRes.locationDetail}');
    if (widget.latitude.isNotEmpty && widget.longitude.isNotEmpty) {
      co = BMFCoordinate(widget.latitude.toDouble, widget.longitude.toDouble);
    }

    // BMFMapStatus? st = await cMs.kmap?.getMapStatus();
    BMFMarker mark = BMFMarker.icon(
      position: locCo ?? co,
      title: title ?? '',
      icon: AstMap.iconLoc,
      isForceDisplay: false,
      canShowCallout: true,
      isLockedToScreen: false,
      selected: false,
      visible: true,
      // screenPointToLock: st?.targetScreenPt,
      draggable: false,
      enabled: true,
      titleOptions: address == null ? null : BMFTitleOptions(fontSize: 36.r ~/ 1, text: address ?? '', fontColor: C.red, titleAnchorY: 1.5.r),
    );
    mark.selected = true;
    logs('--_marker?.title-0-:${mark.title}--_marker--:$_marker');
    if (_marker != null) {
      var ff = await cMs.kmap?.removeMarker(_marker!);
      logs('--ff--:$ff');
    }
    await cMs.kmap?.addMarker(mark);
    _marker = mark;
    // if (locCo != null) hasDraggable = true;
    if (mounted) setState(() {});
  }
  */
}

class InfoTxt extends StatelessWidget {
  final String text;
  const InfoTxt(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: Color(0xFFFFEFD7),
      ),
      constraints: BoxConstraints(minHeight: 30.r),
      child: Row(
        children: [
          Expanded(
            child: MainText(text, color: Colors.red, fontSize: 12.r),
          ),
        ],
      ),
    );
  }
}
