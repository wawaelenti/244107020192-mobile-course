String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route']?.toString() ?? '/';

  if (route.startsWith('/')) {
    return route;
  }

  return '/$route';
}
