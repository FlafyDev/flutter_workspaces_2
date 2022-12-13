{ lib
, buildFlutterApp
}:

buildFlutterApp {
  pname = "flutter-workspaces-2";
  version = "1.0.0";

  src = ../.;

  meta = with lib; {
    description = "bottom_bar";
    homepage = "https://github.com/FlafyDev/flutter_workspaces_2";
    maintainers = [ ];
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
