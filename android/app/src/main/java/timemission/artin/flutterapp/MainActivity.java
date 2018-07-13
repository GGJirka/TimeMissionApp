package timemission.artin.flutterapp;

import android.content.Context;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Bundle;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  private final static String PLATFORM = "artin.timemission/ssid";
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    new MethodChannel(getFlutterView(), PLATFORM).setMethodCallHandler(new MethodChannel.MethodCallHandler() {
      @Override
      public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        if (methodCall.method.equals("getSSID")) {
          WifiManager wifiManager = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
          //result.success("test");
          //if(wifiManager.isWifiEnabled()){
          WifiInfo info = wifiManager.getConnectionInfo();
          result.success(info.getSSID());
            /*
            if(info != null){
              NetworkInfo.DetailedState state = WifiInfo.getDetailedStateOf(info.getSupplicantState());
              //if (state == NetworkInfo.DetailedState.CONNECTED || state == NetworkInfo.DetailedState.OBTAINING_IPADDR) {

              //}
            }*/
        }
        // }
      }
    });
  }
}
