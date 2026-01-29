import 'package:app_kit/core/kt_export.dart';
import 'package:app_kit/tools/button/scale_button.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';

import '../map_small/map_small_logic.dart';

class HideLocation extends StatelessWidget {
  const HideLocation({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _ct();
  }

  Widget _ct() {
    return ScaButton(
      onTap: () async {
        cMs.showMeView.value = !cMs.showMeView.value;
        cMs.kmap?.showUserLocation(cMs.showMeView.value);
        if (onTap != null) onTap!();
      },
      child: Container(
        width: 28.r,
        height: 28.r,
        margin: EdgeInsets.only(bottom: 0.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          color: CC.mainColor,
          boxShadow: const [BoxShadow(color: CC.lightGrey, offset: Offset(0.5, .5), blurRadius: 3.0)],
        ),
        child: Obx(() {
          return Icon(Icons.location_disabled, color: cMs.showMeView.isFalse ? CC.red : CC.white);
        }),
      ),
    );
  }
}
