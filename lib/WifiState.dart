class WifiState {
  static final WifiState _singleton = new WifiState._internal();

  WifiState._internal();

  static WifiState get instance => _singleton;

  String STATE = "LISTEN";

  bool showNotification = false;
}
