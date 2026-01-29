// import 'dart:io';
// import 'package:app_kit/core/kt_export.dart';
// import 'package:flutter_background/flutter_background.dart';
//
// class FlutterBg {
//   Future<void> initPromision() async {
//     if (Platform.isIOS) return;
//     const androidConfig = FlutterBackgroundAndroidConfig(
//         notificationTitle: "后台巡查",
//         notificationText: "Running in the background",
//         notificationImportance: AndroidNotificationImportance.high,
//         enableWifiLock: true);
//     bool hasPermissions =
//         await FlutterBackground.initialize(androidConfig: androidConfig);
//     logs('--hasPermission-initialize-:$hasPermissions');
//     if (hasPermissions) {
//       // Future.delayed(Duration(milliseconds: 1000),(){
//       //   startBackgroundTask();
//       // });
//     }
//   }
//
//   Future<void> startBackgroundTask() async {
//     if (Platform.isIOS) return;
//     bool hasPermission = await hasPermissions();
//     logs('--hasPermission-got-:$hasPermission');
//
//     bool success = await FlutterBackground.enableBackgroundExecution();
//     // logs('--success--:${success}');
//   }
//
//   Future<bool> hasPermissions() async {
//     bool hasPermission = await FlutterBackground.hasPermissions;
//     return hasPermission;
//   }
//
//   Future<void> stopBackgroundTask() async {
//     if (Platform.isIOS) return;
//     await FlutterBackground.disableBackgroundExecution();
//   }
// }
