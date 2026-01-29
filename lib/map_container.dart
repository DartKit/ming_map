
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/src/extensions/widget_extensions.dart';

class MapContainer extends StatefulWidget {
  final Widget child;
  final List<Widget> rights;
  final List<Widget> lefts;
  final List<Widget> bottoms;
  final List<Widget> tops;
  final List<Widget> navs_left;
  final List<Widget> navs;
  final List<Widget> navs_right;
  final EdgeInsets? margin;
  final EdgeInsets? bottomsMargin;

  const MapContainer({super.key, required this.child, this.rights = const [], this.bottoms = const [], this.lefts = const [], this.tops = const [], this.navs = const [], this.navs_left = const [], this.navs_right = const [], this.margin, this.bottomsMargin});

  @override
  State<MapContainer> createState() => _MapContainerState();
}

class _MapContainerState extends State<MapContainer> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 0.r,
          right: 0.r,
          top: 0.r,
          bottom: 0.r,
          child: Column(
            children: [
              if (widget.navs.isNotEmpty || widget.navs_left.isNotEmpty || widget.navs_right.isNotEmpty)
                Container(
                  height: 90.r,
                  decoration: BoxDecoration(
                    //渐变位置从上到下
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [.65, 1.0], colors: [Colors.white, Colors.white.withOpacity(0.1)]),
                  ),
                  child: Column(
                    children: [
                      SafeArea(bottom: false, child: Container(height: 10.r)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 70.r,
                            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: widget.navs_left),
                          ),
                          if (widget.navs.isNotEmpty)
                            Expanded(
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: widget.navs),
                            ),
                          SizedBox(
                            width: 70.r,
                            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: widget.navs_right),
                          ),
                        ],
                      ).marginSymmetric(horizontal: 15.r),
                    ],
                  ),
                ),
              Expanded(
                child: Container(
                  margin: widget.margin,
                  child: Column(
                    children: [
                      if (widget.tops.isNotEmpty)
                        Container(
                          constraints: BoxConstraints(minHeight: 10.r),
                          child: Column(
                              spacing: 10.r,
                              children: widget.tops),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.lefts.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              spacing: 10.r,
                              children: widget.lefts,
                            ),
                          Expanded(child: SizedBox()),
                          if (widget.rights.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              spacing: 10.r,
                              children: widget.rights,
                            ),
                        ],
                      ).marginSymmetric(horizontal: 10.r),

                      Expanded(child: SizedBox()),
                      if (widget.bottoms.isNotEmpty)
                        Container(
                          margin: widget.bottomsMargin,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 10.r,
                            children: widget.bottoms,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
