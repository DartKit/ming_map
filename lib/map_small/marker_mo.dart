import 'package:ming_map/generated/json/base/json_field.dart';
import 'package:ming_map/generated/json/marker_mo.g.dart';
import 'dart:convert';
export 'package:ming_map/generated/json/marker_mo.g.dart';

@JsonSerializable()
class MarkerMo {
	late int id = 0;
	late bool autoSel = false;
	late bool can_select = true;
	// late double scale = 1.0;
	late String title = '';
	late String name = '';
	late String description = '';
	late String longitude = '';
	late String latitude = '';
	late String icon = '';
	late String remark = '';
	dynamic map;

	MarkerMo();

	factory MarkerMo.fromJson(Map<String, dynamic> json) => $MarkerMoFromJson(json);

	Map<String, dynamic> toJson() => $MarkerMoToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}