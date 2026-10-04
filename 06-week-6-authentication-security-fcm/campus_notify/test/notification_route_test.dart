import 'package:campus_notify/messaging/notification_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notificationRouteFromData', () {
    test('accepts app routes supported by the router', () {
      expect(
        notificationRouteFromData({'route': '/pengumuman/3'}),
        '/pengumuman/3',
      );
      expect(notificationRouteFromData({'route': '/'}), '/');
    });

    test('rejects missing, malformed, and external routes', () {
      expect(notificationRouteFromData({}), isNull);
      expect(
        notificationRouteFromData({'route': 'https://example.com'}),
        isNull,
      );
      expect(
        notificationRouteFromData({'route': '//example.com'}),
        isNull,
      );
      expect(
        notificationRouteFromData({'route': '/unknown/route'}),
        isNull,
      );
      expect(
        notificationRouteFromData({'route': '/pengumuman/3?redirect=/'}),
        isNull,
      );
    });
  });
}
