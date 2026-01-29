import 'package:app_kit/core/app_log.dart';

import 'package:app_kit/core/kt_export.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_kit/tools/button/scale_button.dart';
import 'package:flutter/cupertino.dart';

import '../loc_manage.dart';

class MyLocation extends StatelessWidget {
  const MyLocation({super.key, required this.onTap});
  final Function({required BMFCoordinate coo})? onTap;
  @override
  Widget build(BuildContext context) {
    return _ct();
  }

  Widget _ct() {
    return ScaButton(
      onTap: () async {
        // if ((await AppPermission.isGrantedLocation()) == false) return;
        var status = await Permission.location.status;
        if (status.isDenied) {
          status = await Permission.location.request();
        }

        if (status.isPermanentlyDenied) {
          showCupertinoDialog(
            context: Get.context!,
            builder: (context) {
              return CupertinoAlertDialog(
                title: const Text('温馨提示'),
                content: const Text('您已禁止定位权限，请在设置中开启。'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('取消'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  CupertinoDialogAction(
                    child: const Text('去设置'),
                    onPressed: () {
                      Navigator.pop(context);
                      openAppSettings();
                    },
                  ),
                ],
              );
            },
          );
          return;
        }

        if (!status.isGranted) return;

        LocManage().fireLocation(
          firstCall:({required BMFCoordinate coo, String? adr}){
            logs('--x--:$coo');
            if (onTap != null) onTap!(coo: coo);
          },
        );
      },
      child: Container(
        width: 28.r,
        height: 28.r,
        margin: EdgeInsets.only(bottom: 0.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          color: CC.mainColor,
          boxShadow: const [
            BoxShadow(
              color: CC.lightGrey,
              offset: Offset(0.5, .5),
              blurRadius: 3.0,
            ),
          ],
        ),
        child: Icon(Icons.my_location, color: CC.white),
      ),
    );
  }
}
