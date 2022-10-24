import { NativeModules, AppState, Platform } from "react-native";

const { RNPerthWebServer } = NativeModules;

class StaticServer {
  constructor(port, opts) {
    switch (arguments.length) {
      case 2:
        this.port = `${port}`;
        this.localOnly = (arguments[1] && arguments[1].localOnly) || false;
        this.keepAlive = (arguments[1] && arguments[1].keepAlive) || false;

        this.perthKey = (arguments[1] && arguments[1].perthKey) || "";
        this.perthPath = (arguments[1] && arguments[1].perthPath) || "";
        break;
      default:
        this.port = "";
        this.localOnly = false;
        this.keepAlive = false;
        this.perthKey = "";
        this.perthPath = "";
    }

    this.started = false;
    this._origin = undefined;
    this._handleAppStateChangeFn = this._handleAppStateChange.bind(this);
  }

  start() {
    if (this.running) {
      return Promise.resolve(this.origin);
    }

    this.started = true;
    this.running = true;

    if (!this.keepAlive && Platform.OS === "ios") {
      AppState.addEventListener("change", this._handleAppStateChangeFn);
    }

    return RNPerthWebServer.perth_port(
      this.port,
      this.perthKey,
      this.perthPath,
      this.localOnly,
      this.keepAlive
    ).then((origin) => {
      this._origin = origin;
      return origin;
    });
  }

  stop() {
    this.running = false;

    return RNPerthWebServer.perth_stop();
  }

  kill() {
    this.stop();
    this.started = false;
    this._origin = undefined;
    AppState.removeEventListener("change", this._handleAppStateChangeFn);
  }

  _handleAppStateChange(appState) {
    if (!this.started) {
      return;
    }

    if (appState === "active" && !this.running) {
      this.start();
    }

    if (appState === "background" && this.running) {
      this.stop();
    }

    if (appState === "inactive" && this.running) {
      this.stop();
    }
  }

  get origin() {
    return this._origin;
  }

  isRunning() {
    return RNPerthWebServer.perth_isRunning().then((running) => {
      this.running = running;

      return this.running;
    });
  }
}

export default StaticServer;
