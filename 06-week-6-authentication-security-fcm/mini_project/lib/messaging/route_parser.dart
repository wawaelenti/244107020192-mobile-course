String? notificationRouteFromData(Map<String, dynamic> data) {
  final route = data['route'];
  if (route is String) {
    final uri = Uri.tryParse(route);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }

    final segments = uri.pathSegments;
    if (segments.length == 2 &&
        segments.first == 'pengumuman' &&
        RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(segments.last)) {
      return '/pengumuman/${Uri.encodeComponent(segments.last)}';
    }
    return null;
  }

  final id = data['id'];
  if (id is String && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) {
    return '/pengumuman/${Uri.encodeComponent(id)}';
  }
  return null;
}
