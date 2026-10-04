class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const announcement = '/pengumuman/:id';

  static String announcementById(String id) {
    return '/pengumuman/$id';
  }
}
