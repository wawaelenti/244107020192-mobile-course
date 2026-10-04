String? notificationRouteFromData(Map<String, dynamic> data) {
  final route = data['route'];
  if (route is! String) {
    return null;
  }

  if (route == '/') {
    return route;
  }

  final uri = Uri.tryParse(route);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }

  final segments = uri.pathSegments;
  if (segments.length != 2 ||
      segments.first != 'pengumuman' ||
      !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(segments.last)) {
    return null;
  }

  return '/pengumuman/${Uri.encodeComponent(segments.last)}';
}
