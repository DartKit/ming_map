import 'package:ming_map/generated/json/base/json_convert_content.dart';
import 'package:ming_map/map_small/marker_mo.dart';

MarkerMo $MarkerMoFromJson(Map<String, dynamic> json) {
  final MarkerMo markerMo = MarkerMo();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    markerMo.id = id;
  }
  final bool? autoSel = jsonConvert.convert<bool>(json['autoSel']);
  if (autoSel != null) {
    markerMo.autoSel = autoSel;
  }
  final bool? can_select = jsonConvert.convert<bool>(json['can_select']);
  if (can_select != null) {
    markerMo.can_select = can_select;
  }
  final String? title = jsonConvert.convert<String>(json['title']);
  if (title != null) {
    markerMo.title = title;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    markerMo.name = name;
  }
  final String? description = jsonConvert.convert<String>(json['description']);
  if (description != null) {
    markerMo.description = description;
  }
  final String? longitude = jsonConvert.convert<String>(json['longitude']);
  if (longitude != null) {
    markerMo.longitude = longitude;
  }
  final String? latitude = jsonConvert.convert<String>(json['latitude']);
  if (latitude != null) {
    markerMo.latitude = latitude;
  }
  final String? icon = jsonConvert.convert<String>(json['icon']);
  if (icon != null) {
    markerMo.icon = icon;
  }
  final String? remark = jsonConvert.convert<String>(json['remark']);
  if (remark != null) {
    markerMo.remark = remark;
  }
  final dynamic map = json['map'];
  if (map != null) {
    markerMo.map = map;
  }
  return markerMo;
}

Map<String, dynamic> $MarkerMoToJson(MarkerMo entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['autoSel'] = entity.autoSel;
  data['can_select'] = entity.can_select;
  data['title'] = entity.title;
  data['name'] = entity.name;
  data['description'] = entity.description;
  data['longitude'] = entity.longitude;
  data['latitude'] = entity.latitude;
  data['icon'] = entity.icon;
  data['remark'] = entity.remark;
  data['map'] = entity.map;
  return data;
}

extension MarkerMoExtension on MarkerMo {
  MarkerMo copyWith({
    int? id,
    bool? autoSel,
    bool? can_select,
    String? title,
    String? name,
    String? description,
    String? longitude,
    String? latitude,
    String? icon,
    String? remark,
    dynamic map,
  }) {
    return MarkerMo()
      ..id = id ?? this.id
      ..autoSel = autoSel ?? this.autoSel
      ..can_select = can_select ?? this.can_select
      ..title = title ?? this.title
      ..name = name ?? this.name
      ..description = description ?? this.description
      ..longitude = longitude ?? this.longitude
      ..latitude = latitude ?? this.latitude
      ..icon = icon ?? this.icon
      ..remark = remark ?? this.remark
      ..map = map ?? this.map;
  }
}