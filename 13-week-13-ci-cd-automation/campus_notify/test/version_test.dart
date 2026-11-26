import 'package:flutter_test/flutter_test.dart';

import '../tool/check_version.dart';

void main() {
  group('Versioning', () {
    test('memisahkan versi aplikasi dan build number', () {
      final version = readAppVersion('version: 1.2.0+15');

      expect(version.name, '1.2.0');
      expect(version.buildNumber, 15);
      expect(version.fullVersion, '1.2.0+15');
      expect(version.tag, 'v1.2.0');
    });

    test('menerima prerelease SemVer dan versi dengan tanda kutip', () {
      final version = readAppVersion('version: "1.2.0-rc.1+15"');

      expect(version.name, '1.2.0-rc.1');
      expect(version.buildNumber, 15);
      expect(version.tag, 'v1.2.0-rc.1');
    });

    test('menolak versi atau build number yang tidak valid', () {
      for (final value in [
        '1.2.0',
        '1.2+15',
        '01.2.0+15',
        '1.2.0+0',
        '1.2.0+01',
        '1.2.0+abc',
        '1.2.0-01+15',
      ]) {
        expect(
          () => readAppVersion('version: $value'),
          throwsFormatException,
          reason: value,
        );
      }
    });

    test('menolak YAML rusak atau tanpa field version yang benar', () {
      for (final pubspec in ['version: [', 'name: app', 'version: 15']) {
        expect(() => readAppVersion(pubspec), throwsFormatException);
      }
    });

    test('menerima tag yang sesuai versi aplikasi', () {
      final version = readAppVersion('version: 1.2.0+15');

      expect(
        () => validateVersionTag(version, 'refs/tags/v1.2.0'),
        returnsNormally,
      );
    });

    test('menolak tag versi berbeda atau tag dengan build suffix', () {
      final version = readAppVersion('version: 1.2.0+15');

      for (final tag in ['v1.2.1', 'v1.2.0+15']) {
        expect(
          () => validateVersionTag(version, 'refs/tags/$tag'),
          throwsFormatException,
        );
      }
    });

    test('build branch dan pull request tidak memerlukan tag', () {
      final version = readAppVersion('version: 1.2.0+15');

      for (final ref in ['', 'refs/heads/develop', 'refs/pull/42/merge']) {
        expect(() => validateVersionTag(version, ref), returnsNormally);
      }
    });
  });
}
