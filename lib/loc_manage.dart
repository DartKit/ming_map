import 'dart:io';
import 'package:app_kit/core/app_define.dart';
import 'package:app_kit/core/app_log.dart';
import 'package:app_kit/core/app_permission.dart';
import 'package:app_kit/core/kt_export.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:get/get.dart';

import 'map_options.dart';


BaiduLocation get klocRes => LocManage().locRes.value; // 当前定位结果
bool? kSetLoc; // 外部设置-开启定位。主要在Main中全局轮询判断
// bool? cancelDelayStop; // 取消延时定位

typedef LocCall = Function ({required BMFCoordinate coo, required String adr});

class LocManage {
  static LocManage? _instance;
  LocManage._internal() {
    _instance = this;
    // _init();
  }
  factory LocManage() => _instance ?? LocManage._internal();
  static LocManage get instance => _instance!;

  /// 以下是定位业务
  final LocationFlutterPlugin myLocPlugin = LocationFlutterPlugin();
  static bool hasInit = false;
  /// 日志等级 0无 1简单定位数据 2详细定位数据
  static int log_level = 2;
  var locRes = BaiduLocation().obs;
  /// 当前定位点
  static BMFCoordinate get loc =>  klocRes.latitude == null? MapOptions.initCoordinate: BMFCoordinate(klocRes.latitude!, klocRes.longitude!);
  /// 是否正在定位
  static bool get isLocing => ((_locTimes >= 1) && (instance.lastLocTimeGap < 180));
  static var _locTimes = 0;

  LocCall? _onceCall;
  LocCall? _firstCall;

  /// 上次定位时间和目前当前时间，间隔时间越小，定位越是正常的-gap
  int get lastLocTimeGap  {
    var gg = 10000;
    if (_locTimes == 0) return gg;
    if (locRes.value.callbackTime == null) return gg;
    var gap=  DateTime.now().difference(DateTime.parse(locRes.value.callbackTime!)).inSeconds;
    logs('上次定位时间和目前当前时间，间隔时间越小，定位越是正常的-gap--:$gap');
    return gap;
  }

  /// 定位初始化 要在本地app允许隐私协议后调用。
  /// [ak_ios] iOS平台的地图秘钥。
  Future<LocManage?>? init({required ak_ios}) async {
    BMFMapSDK.setAgreePrivacy(true);
    myLocPlugin.setAgreePrivacy(true);

    if (Platform.isIOS) {
      /// 设置ios端ak, android端ak可以直接在清单文件中配置
      myLocPlugin.authAK(ak_ios);
      BMFMapSDK.setApiKeyAndCoordType(ak_ios, BMF_COORD_TYPE.BD09LL);
    } else if (Platform.isAndroid) {
      // Android 目前不支持接口设置Apikey,
      // 请在主工程的Manifest文件里设置，详细配置方法请参考官网(https://lbsyun.baidu.com/)demo
      BMFMapSDK.setCoordType(BMF_COORD_TYPE.BD09LL);
    }

    /// iOS端鉴权结果
    myLocPlugin.getApiKeyCallback(callback: (String result) {
      String str = result;
      logs('鉴权结果：$str');
    });
    bool f = await _setLocationOption();
    logs('--f--:$f');
    _locationCallback();
    hasInit = true;
    return _instance;
  }



  void _locationCallback() {
    /*
    ///单次定位时如果是安卓可以在内部进行判断调用连续定位
    if (Platform.isIOS) {
      ///接受定位回调
      myLocPlugin.singleLocationCallback(callback: (BaiduLocation result) {
        locRes.value = result;
        locationFinish(result);
      });
    } else if (Platform.isAndroid) {
      ///接受定位回调
      myLocPlugin.seriesLocationCallback(callback: (BaiduLocation result) {
        locRes.value = result;
        locationFinish(result);
      });
    }
*/
    ///  接受定位回调
    myLocPlugin.seriesLocationCallback(callback: (BaiduLocation result) {
     if (log_level >= 1) logs('连续定位-位置：${result.address}--latitude-:${result.latitude}-longitude-:${result.longitude}--code--:${result.errorCode}-errorInfo--:${result.errorInfo}');
      _setLoc(result);
    });

    myLocPlugin.singleLocationCallback(callback: (BaiduLocation result) {
      if (log_level >= 1) logs('单次定位-位置：${result.address}--latitude-:${result.latitude}-longitude-:${result.longitude}--code--:${result.errorCode}-errorInfo--:${result.errorInfo}');
      _setLoc(result);
      // _scheduleTask();
    });
  }

  Future<void> _setLoc(BaiduLocation result) async {
    if (log_level >= 2) logs('--result--:${result.getMap()}');
    var locOk = false;
    // https://lbsyun.baidu.com/faq/api?title=android-locsdk/guide/addition-func/error-code
    if(inAndroid) if ((result.errorCode == 61) || ((result.errorCode == 66) || ((result.errorCode == 161)))) locOk = true;
    if(inIOS) locOk = true;
    if (locOk == false) return;
    if (result.latitude == null) return;
    locationFinish(result);

  }

  ///开始定位
  /// [onceCall] 只获取一次定位，
  /// 如果当前没有开启定位，则开启连续定位，并获取一次定位结果后自动停止定位。
  /// 如果当前已经正在定位，则获取最近一次定位结果，不会自动停止定位。
  /// [firstCall] 第一次定位结果回调
  /// 执行[fireLocation]后会开启定位，返回第一次定位结果后不再回调。回调完成会处置为null。
  void fireLocation({LocCall? onceCall, LocCall? firstCall}) async {
    // if (Platform.isIOS) {
    //   _suc = await myLocPlugin
    //       .singleLocation({'isReGeocode': true, 'isNetworkState': true});
    //   logs('开始单次定位：$_suc');
    // } else if (Platform.isAndroid) {
    //   _suc = await myLocPlugin.startLocation();
    // }
    // _suc = await myLocPlugin.singleLocation({'isReGeocode': true, 'isNetworkState': true});
    if (isNil(await AppPermission.isGrantedLocation() == false, '当前无定位权限')) return;
    if (log_level > 0) logs('--firstCall--:$firstCall--onceCall--:$onceCall--isLocing--:$isLocing--_locTimes--:$_locTimes');
    if (firstCall != null)  _firstCall = firstCall;
    if (onceCall != null) {
      if (isLocing) {
        onceCall(coo:loc,adr: '');
        return;
      } else {
        _onceCall = onceCall;
        var suc = await myLocPlugin.startLocation();
        logs('onceCall开始连续定位：$suc');
      }
    } else {
      if (isLocing) {
        return;
      }
      var suc = await myLocPlugin.startLocation();
      logs('开始连续定位：$suc');
    }
  }

  /// 停止定位
  Future<void> stopLocation({int delay = 0}) async {
    if (log_level > 0) logs('--delay-0-:$delay--_locTimes--:$_locTimes--kSetLoc--:$kSetLoc');
    Future.delayed(Duration(seconds: delay), () async {
      bool fl = await myLocPlugin.stopLocation();
      if (fl) {
        kSetLoc = null;
        _locTimes = 0;
        Future.delayed(Duration(seconds: 5), () {
          if (_locTimes > 0){
            if (log_level > 0) logs('--5s之前stopLocation-停止定位不成功-:seconds:5后再次执行停止}');
            stopLocation();
          }
        });
      }
    });
  }

  /// 定位完成添加mark
  Future locationFinish(BaiduLocation result) async {
    if ((result.longitude != null) && (result.latitude != null)) {
      locRes.value = result;
      _locTimes++;
      lastLocTimeGap;
      if (kSetLoc != null)  Future.delayed(Duration(milliseconds: 5000), ()=>kSetLoc = null);
      if (_firstCall != null) {
        _firstCall!(coo:  BMFCoordinate(result.latitude!, result.longitude!),adr: result.address??'');
        _firstCall = null;
      }
      if (_onceCall != null) {
        _onceCall!(coo:  BMFCoordinate(result.latitude!, result.longitude!),adr: result.address??'');
        _onceCall = null;
        Future.delayed(Duration(milliseconds: 4000), () async {
          if (log_level > 0) logs('-之前没有定位，已经开启了一次定位_onceCall回调后-执行stopLocation--}');
          stopLocation();
        });
      }
    }
  }


  /// 设置定位参数
  Future<bool> _setLocationOption() async {
    Map iosMap = MapOptions.initIOSOptions().getMap();
    Map androidMap = MapOptions.initAndroidOptions().getMap();
    bool f = await myLocPlugin.prepareLoc(androidMap, iosMap);
    logs('设置定位参数：-f--$f-----iosMap--$iosMap-----androidMap--$androidMap');
    return f;
  }

}
