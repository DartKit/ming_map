import 'package:app_kit/core/kt_export.dart';
import 'package:app_kit/tools/button/scale_button.dart';
import 'package:app_kit/widgets/kit_views/kit_view.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import '../map_small/map_small_logic.dart';
import '../polygon_editor/polygon_editor_logic.dart';

class BtnClearPolygon extends StatelessWidget {
  const BtnClearPolygon({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (cPolE.mapMarkers.isEmpty) return SizedBox();
      return _ct();
    });
  }

  Widget _ct() {
    return ScaButton(
      onTap: () async {
        KitView.alert(content: '您要清空当前编辑的围栏吗？', sure: () {
          cMs.kmap?.removeMarkers(cPolE.mapMarkers);
          cPolE.mapMarkers.clear();
          if (cMs.act_polygon != null) {
            cMs.kmap?.removeOverlay(cMs.act_polygon!.id);
            cMs.act_polygon = null;
          }
        });
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
        child: Icon(Icons.wrong_location_outlined, color: CC.white),
      ),
    );
  }
}
