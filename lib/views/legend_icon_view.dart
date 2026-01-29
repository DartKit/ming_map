import 'package:app_kit/core/kt_export.dart';

// 地图图例
class LegendMo {
   String icon;
   String name;
   String num;
   String color;
   LegendMo({this.icon = '', this.name = '', this.num = '', this.color = ''});
}

class LegendIconView extends StatelessWidget {
  final EdgeInsets? margin;
  final List<LegendMo> ls;
  final Size? iconSize;

  const LegendIconView({super.key, this.margin, required this.ls,this.iconSize});

  @override
  Widget build(BuildContext context) {
    return _ct();
  }

  Widget _ct() {
    if (ls.isEmpty) return SizedBox();
    List<Widget> co0 = [];
    List<Widget> co1 = [];
    // bool hasIcon = false;
    for (var i = 0; i < ls.length; ++i) {
      var o = ls[i];
      var name = SizedBox(
          height: 20.r,
          child: Row(
            children: [
              if (o.icon.isNotEmpty)
                CoImage(
                  o.icon,
                  width: iconSize?.width?? 12.r,
                  height: iconSize?.height??16.r,
                  circular: 0,
                  fit: BoxFit.fill,
                ).marginOnly(right: 5.r),
              if (o.color.isNotEmpty)
                Container(
                  width: 8.r,
                  height: 8.r,
                  margin: EdgeInsets.only(right: 5.r),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.r), color: CC.hex(o.color.ifNil('#FF666666'))),
                ),
              Text(
                o.name,
                style: TextStyle(color: CC.hex(o.color.ifNil('#FF666666')), fontSize: 12.sp, fontWeight: AppFont.medium),
              ),
            ],
          ));
      var num = SizedBox(
          height: 20.r,
          child: Center(
              child: Text(
            o.num.toString(),
            style: TextStyle(color: CC.black, fontSize: 14.r, fontWeight: AppFont.semiBold),
          )));
      co0.add(name);
      co1.add(num);
    }
    return Container(
      padding: EdgeInsets.all(6.r),
      margin: margin ?? EdgeInsets.only(top: 0.r, bottom: 0.r),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.r), color: CC.white.withValues(alpha: 0.80)),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.r),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: co0,
            ),
            SizedBox(
              width: 10.r,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: co1,
            ),
          ],
        ),
      ),
    );
  }
}
