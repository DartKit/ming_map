import 'dart:math' as Math;
import 'package:flutter_baidu_mapapi_utils/flutter_baidu_mapapi_utils.dart';
// import 'package:app_kit/core/kt_export.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';

/// 轨迹优化工具类 Android
/// <p>
/// 使用方法：
/// <p>
///     PathSmoothTool pathSmoothTool = new PathSmoothTool();
///     pathSmoothTool.setIntensity(2);//设置滤波强度，默认3
///     List<BMFCoordinate> mList = LatpathSmoothTool.kalmanFilterPath(list);

class PathSmoothTool {
  static PathSmoothTool? _instance;
  PathSmoothTool._internal() {
    _instance = this;
    // initial();
  }
  factory PathSmoothTool() => _instance ?? PathSmoothTool._internal();

  ///判空符??
  // 如下都是单例以外的业务

  int mIntensity = 2;
  double mThreshhold = 0.6; // 抽稀 删除两点间距小于 mThreshhold 点
  double mNoiseThreshhold = 20; // 删除点到线垂足大于该值的点。

  // PathSmoothTool(){}
  void reset() {
    mIntensity = 2;
    mThreshhold = 0.6;
    mNoiseThreshhold = 20;
  }

  int getIntensity() {
    return mIntensity;
  }

  void setIntensity(int x) {
    mIntensity = x;
  }

  double getThreshhold() {
    return mThreshhold;
  }

  void setThreshhold(double x) {
    mThreshhold = x;
  }

  void setNoiseThreshhold(double x) {
    mNoiseThreshhold = x;
  }

  /// 轨迹平滑优化
  /// @param originlist 原始轨迹list,list.size大于2
  /// @return 优化后轨迹list
  Future<List<BMFCoordinate>> pathOptimize(
      List<BMFCoordinate> originlist) async {
    if (originlist.length <= 3) return originlist;
    List<BMFCoordinate> list = await removeNoisePoint(originlist); //去噪
    List<BMFCoordinate> afterList = kalmanFilterPath(list, mIntensity); //滤波
    List<BMFCoordinate> pathoptimizeList =
        await reducerVerticalThreshold(afterList, mThreshhold); //抽稀
    // pathoptimizeList =  await reduceNoisePoint(pathoptimizeList,mNoiseThreshhold);//去噪
//        Log.i("MY","originlist: "+originlist.size());
//        Log.i("MY","list: "+list.size());
//        Log.i("MY","afterList: "+afterList.size());
//        Log.i("MY","pathoptimizeList: "+pathoptimizeList.size());
    return pathoptimizeList;
  }

  /**
   * 轨迹线路滤波
   * @param originlist 原始轨迹list,list.size大于2
   * @return 滤波处理后的轨迹list
   */
  // List<BMFCoordinate> kalmanFilterPath(List<BMFCoordinate> originlist, int mIntensity) {
  //   return kalmanFilterPath(originlist,mIntensity);
  // }

  /// 轨迹去噪，删除垂距大于 mNoiseThreshhold  m的点 默认是20m
  /// @param originlist 原始轨迹list,list.size大于2
  /// @return
  Future<List<BMFCoordinate>> removeNoisePoint(
      List<BMFCoordinate> originlist) async {
    return await reduceNoisePoint(originlist, mNoiseThreshhold);
  }

  /**
   * 单点滤波
   * @param lastLoc 上次定位点坐标
   * @param curLoc 本次定位点坐标
   * @return 滤波后本次定位点坐标值
   */
  // BMFCoordinate kalmanFilterPoint(BMFCoordinate lastLoc, BMFCoordinate curLoc, int mIntensity) {
  //   return kalmanFilterPoint(lastLoc,curLoc,mIntensity);
  // }

  /**
   * 轨迹抽稀
   * @param inPoints 待抽稀的轨迹list，至少包含两个点，删除垂距小于mThreshhold的点
   * @return 抽稀后的轨迹list
   */
  // List<BMFCoordinate> reducerVerticalThreshold(List<BMFCoordinate> inPoints, double mThreshhold) {
  //   return reducerVerticalThreshold(inPoints,mThreshhold);
  // }

  /********************************************************************************************************/
  /// 轨迹线路滤波
  /// @param originlist 原始轨迹list,list.size大于2
  /// @param intensity 滤波强度（1—5）
  /// @return
  List<BMFCoordinate> kalmanFilterPath(
      List<BMFCoordinate> originlist, int intensity) {
    List<BMFCoordinate> kalmanFilterList = [];
    if (originlist.length <= 2) return kalmanFilterList;
    initial(); //初始化滤波参数
    BMFCoordinate loc;
    BMFCoordinate lastLoc = originlist.first;
    kalmanFilterList.add(lastLoc);
    for (int i = 1; i < originlist.length; i++) {
      BMFCoordinate curLoc = originlist[i];
      loc = kalmanFilterPoint(lastLoc, curLoc, intensity);
      if (loc.longitude != 0.0) {
        kalmanFilterList.add(loc);
        lastLoc = loc;
      }
    }
    return kalmanFilterList;
  }

  /// 单点滤波
  /// @param lastLoc 上次定位点坐标
  /// @param curLoc 本次定位点坐标
  /// @param intensity 滤波强度（1—5）
  /// @return 滤波后本次定位点坐标值
  BMFCoordinate kalmanFilterPoint(
      BMFCoordinate lastLoc, BMFCoordinate curLoc, int intensity) {
    if (pdelt_x == 0 || pdelt_y == 0) {
      initial();
    }
    late BMFCoordinate kalmanLatlng;
    // if (lastLoc == null || curLoc == null){
    //   return kalmanLatlng;
    // }
    if (intensity < 1) {
      intensity = 1;
    } else if (intensity > 10) {
      intensity = 10;
    }
    for (int j = 0; j < intensity; j++) {
      kalmanLatlng = kalmanFilter(lastLoc.longitude, curLoc.longitude,
          lastLoc.latitude, curLoc.latitude);
      curLoc = kalmanLatlng;
    }
    return kalmanLatlng;
  }

  /// *************************卡尔曼滤波开始*******************************
  late double lastLocation_x; //上次位置
  late double currentLocation_x; //这次位置
  late double lastLocation_y; //上次位置
  late double currentLocation_y; //这次位置
  late double estimate_x; //修正后数据
  late double estimate_y; //修正后数据
  late double pdelt_x; //自预估偏差
  late double pdelt_y; //自预估偏差
  late double mdelt_x; //上次模型偏差
  late double mdelt_y; //上次模型偏差
  late double gauss_x; //高斯噪音偏差
  late double gauss_y; //高斯噪音偏差
  late double kalmanGain_x; //卡尔曼增益
  late double kalmanGain_y; //卡尔曼增益

  double m_R = 0;
  double m_Q = 0;
  //初始模型
  void initial() {
    pdelt_x = 0.001;
    pdelt_y = 0.001;
//        mdelt_x = 0;
//        mdelt_y = 0;
    mdelt_x = 5.698402909980532E-4;
    mdelt_y = 5.698402909980532E-4;
  }

  BMFCoordinate kalmanFilter(
      double oldvalueX, double valueX, double oldvalueY, double valueY) {
    lastLocation_x = oldvalueX;
    currentLocation_x = valueX;
    gauss_x = Math.sqrt(pdelt_x * pdelt_x + mdelt_x * mdelt_x) + m_Q; //计算高斯噪音偏差
    kalmanGain_x = Math.sqrt(
            (gauss_x * gauss_x) / (gauss_x * gauss_x + pdelt_x * pdelt_x)) +
        m_R; //计算卡尔曼增益
    estimate_x = kalmanGain_x * (currentLocation_x - lastLocation_x) +
        lastLocation_x; //修正定位点
    mdelt_x = Math.sqrt((1 - kalmanGain_x) * gauss_x * gauss_x); //修正模型偏差

    lastLocation_y = oldvalueY;
    currentLocation_y = valueY;
    gauss_y = Math.sqrt(pdelt_y * pdelt_y + mdelt_y * mdelt_y) + m_Q; //计算高斯噪音偏差
    kalmanGain_y = Math.sqrt(
            (gauss_y * gauss_y) / (gauss_y * gauss_y + pdelt_y * pdelt_y)) +
        m_R; //计算卡尔曼增益
    estimate_y = kalmanGain_y * (currentLocation_y - lastLocation_y) +
        lastLocation_y; //修正定位点
    mdelt_y = Math.sqrt((1 - kalmanGain_y) * gauss_y * gauss_y); //修正模型偏差

    // BMFCoordinate loc =  BMFCoordinate(estimate_y,estimate_x);
    BMFCoordinate loc = BMFCoordinate(estimate_y, estimate_x);

    return loc;
  }
  /***************************卡尔曼滤波结束**********************************/

  /// *************************抽稀算法************************************
  Future<List<BMFCoordinate>> reducerVerticalThreshold(
      List<BMFCoordinate> inPoints, double threshHold) async {
    if (inPoints.length <= 2) return inPoints;
    List<BMFCoordinate> ret = [];
    for (int i = 0; i < inPoints.length; i++) {
      BMFCoordinate pre = ret.isNotEmpty ? ret.last : inPoints.first;
      BMFCoordinate cur = inPoints[i];
      if (i == inPoints.length - 1) {
        ret.add(cur);
        continue;
      }
      if (i + 1 < inPoints.length) {
        BMFCoordinate next = inPoints[i + 1];
        double distance = await calculateDistanceFromPoint(cur, pre, next);
        if (distance > threshHold) {
          ret.add(cur);
        }
      }
    }
    return ret;
  }
  //  BMFCoordinate? getLastLocation(List<BMFCoordinate> oneGraspList) {
  //   if (oneGraspList.isEmpty) {
  //     return null;
  //   }
  //   int locListSize = oneGraspList.length;
  //   BMFCoordinate lastLocation = oneGraspList[locListSize - 1];
  //   return lastLocation;
  // }

  /// 计算当前点到线的垂线距离
  /// @param p 当前点
  /// @param lineBegin 线的起点
  /// @param lineEnd 线的终点
  ///
  Future<double> calculateDistanceFromPoint(
      BMFCoordinate p, BMFCoordinate lineBegin, BMFCoordinate lineEnd) async {
    double A = p.longitude - (lineBegin.longitude);
    double B = p.latitude - (lineBegin.latitude);
    double C = lineEnd.longitude - (lineBegin.longitude);
    double D = lineEnd.latitude - (lineBegin.latitude);

    double dot = A * C + B * D;
    double lenSq = C * C + D * D;
    double param = dot / lenSq;

    double xx, yy;

    if (param < 0 ||
        (lineBegin.longitude == lineEnd.longitude &&
            lineBegin.latitude == lineEnd.latitude)) {
      xx = lineBegin.longitude;
      yy = lineBegin.latitude;
//            return -1;
    } else if (param > 1) {
      xx = lineEnd.longitude;
      yy = lineEnd.latitude;
//            return -1;
    } else {
      xx = lineBegin.longitude + param * C;
      yy = lineBegin.latitude + param * D;
    }

    return await BMFCalculateUtils.getLocationDistance(
            BMFCoordinate(p.latitude, p.longitude), BMFCoordinate(yy, xx)) ??
        0;
    // return AMapUtils.calculateLineDistance(p, BMFCoordinate()..longitude=xx..latitude=yy);
  }

  /// *************************抽稀算法结束********************************

  Future<List<BMFCoordinate>> reduceNoisePoint(
      List<BMFCoordinate> inPoints, double threshHold) async {
    if (inPoints.length <= 2) {
      return inPoints;
    }
    List<BMFCoordinate> ret = [];

    for (int i = 0; i < inPoints.length; i++) {
      BMFCoordinate pre = ret.isNotEmpty ? ret.last : inPoints.first;
      BMFCoordinate cur = inPoints[i];
      if (i == inPoints.length - 1) {
        ret.add(cur);
        continue;
      }
      if (i + 1 < inPoints.length) {
        BMFCoordinate next = inPoints[i + 1];
        double distance = await calculateDistanceFromPoint(cur, pre, next);
        if (distance < threshHold) {
          ret.add(cur);
        }
      }
    }
    return ret;
  }
}
