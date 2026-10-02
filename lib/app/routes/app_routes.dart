abstract class Routes {
  Routes._();

  static const splash = _Paths.splash;
  static const login = _Paths.login;
  static const register = _Paths.register;
  static const home = _Paths.home;
  static const monitoring = _Paths.monitoring;
  static const screenTime = _Paths.screenTime;
  static const doomscrolling = _Paths.doomscrolling;
  static const eyeMonitoring = _Paths.eyeMonitoring;
  static const insight = _Paths.insight;
  static const profile = _Paths.profile;
  static const editProfile = _Paths.editProfile;
  static const permissionGuide = _Paths.permissionGuide;
  static const intervention = _Paths.intervention;
  static const eyeRelaxation = _Paths.eyeRelaxation;
  static const focusMode = _Paths.focusMode;
  static const interventionHistory = _Paths.interventionHistory;
}

abstract class _Paths {
  _Paths._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const monitoring = '/monitoring';
  static const screenTime = '/monitoring/screen-time';
  static const doomscrolling = '/monitoring/doomscrolling';
  static const eyeMonitoring = '/monitoring/eye';
  static const insight = '/insight';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const permissionGuide = '/permission-guide';
  static const intervention = '/intervention';
  static const eyeRelaxation = '/intervention/eye-relaxation';
  static const focusMode = '/intervention/focus-mode';
  static const interventionHistory = '/intervention-history';
}
