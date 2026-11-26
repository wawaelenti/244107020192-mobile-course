import 'dart:io';

import 'package:yaml/yaml.dart';

class AppVersion {
  const AppVersion(this.name, this.buildNumber);

  final String name;
  final int buildNumber;

  String get fullVersion => '$name+$buildNumber';
  String get tag => 'v$name';
}

AppVersion readAppVersion(String pubspec) {
  final Object? document;
  try {
    document = loadYaml(pubspec);
  } on YamlException {
    throw const FormatException('pubspec.yaml bukan YAML yang valid.');
  }
  final value = document is YamlMap ? document['version'] : null;
  if (value is! String) {
    throw const FormatException('Field version wajib berupa string.');
  }

  final match = RegExp(
    r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)'
    r'(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?\+([1-9][0-9]*)$',
  ).firstMatch(value);
  final buildNumber = match == null ? null : int.tryParse(match.group(5)!);
  if (match == null || buildNumber == null) {
    throw const FormatException(
      'Gunakan MAJOR.MINOR.PATCH+BUILD dengan build number positif.',
    );
  }
  for (final identifier in match.group(4)?.split('.') ?? <String>[]) {
    if (RegExp(r'^0[0-9]+$').hasMatch(identifier)) {
      throw const FormatException(
        'Identifier prerelease numerik tidak boleh diawali nol.',
      );
    }
  }
  return AppVersion(value.split('+').first, buildNumber);
}

void validateVersionTag(AppVersion version, String ref) {
  if (ref.startsWith('refs/tags/') && ref != 'refs/tags/${version.tag}') {
    throw FormatException('Tag harus ${version.tag}, sesuai pubspec.yaml.');
  }
}

void main(List<String> arguments) {
  try {
    if (arguments.length > 1 ||
        (arguments.isNotEmpty && !arguments.single.startsWith('--ref='))) {
      throw const FormatException('Argumen opsional: --ref=refs/tags/vX.Y.Z');
    }
    final version = readAppVersion(File('pubspec.yaml').readAsStringSync());
    final ref = arguments.isEmpty
        ? Platform.environment['GITHUB_REF'] ?? ''
        : arguments.single.substring('--ref='.length);
    validateVersionTag(version, ref);
    stdout.writeln(
      'Versi: ${version.fullVersion}; tag yang sesuai: ${version.tag}',
    );

    final sha = Platform.environment['GITHUB_SHA'];
    if (sha != null &&
        RegExp(r'^(?:[a-fA-F0-9]{40}|[a-fA-F0-9]{64})$').hasMatch(sha)) {
      stdout.writeln('Source commit: $sha');
    }
    final output = Platform.environment['GITHUB_OUTPUT'];
    if (output != null) {
      File(output).writeAsStringSync(
        'version_name=${version.name}\nbuild_number=${version.buildNumber}\n',
        mode: FileMode.append,
      );
    }
  } on FormatException catch (error) {
    stderr.writeln('Pemeriksaan versi gagal: ${error.message}');
    exitCode = 1;
  }
}
