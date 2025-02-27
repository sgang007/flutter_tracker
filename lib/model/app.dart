import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  String? version;
  String? buildNumber;

  AppVersion({
    this.version,
    this.buildNumber,
  });

  factory AppVersion.fromJson(
    Map<dynamic, dynamic>? json,
  ) {
    if (json == null) {
      return AppVersion();
    }

    return AppVersion(
      version: json['version'],
      buildNumber: json['build_number'],
    );
  }

  AppVersion fromPackageInfo(
    PackageInfo? packageInfo,
  ) {
    if (packageInfo == null) {
      return AppVersion();
    }

    return AppVersion(
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }

  Map<String, dynamic>? toMap(
    AppVersion? version,
  ) {
    if (version == null) {
      return null;
    }

    Map<String, dynamic> versionMap = {};
    versionMap['version'] = version.version;
    versionMap['build_number'] = version.buildNumber;
    return versionMap;
  }
}
