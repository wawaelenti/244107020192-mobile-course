const String loginRoute = '/login';
const String homeRoute = '/';
const String announcementRoute = '/pengumuman/:id';

String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route'];

  if (route is! String || route.isEmpty) {
    return homeRoute;
  }

  if (!route.startsWith('/')) {
    return '/$route';
  }

  return route;
}
