import 'package:ming_map/generated/assets.dart';

/// ast_tool_map.dart
class AstToolMap {
  /// 获取包内资源路径
  /// [assetsPath] 原始资源路径，如 lib/ast/images/act_line.png
  /// 返回: packages/ming_map/lib/ast/images/act_line.png
  static String pkgAst(String assetsPath) {
    if (assetsPath.startsWith('packages/')) {
      return assetsPath;
    }
    // 注意：这里 assuming ming_map 是包名。
    // 如果 assetsPath 已经包含 lib/ 前缀，通常 packages/pakage_name/lib/... 是不对的
    // Flutter 资源引用通常是 packages/package_name/path/to/asset
    // 如果 pubspec 中声明的是 lib/ast/，那么引用时是 packages/ming_map/lib/ast/... 还是 packages/ming_map/ast/... ?
    // Check pubspec again:
    // assets:
    //   - lib/ast/
    //
    // If declared as lib/ast/, then the asset key is "packages/ming_map/lib/ast/..."

    return 'packages/${AstMap.package}/$assetsPath';
  }
}
