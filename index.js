import { NativeModules, AppState, Platform } from "react-native";

const { RNAustraliaWebServer } = NativeModules;

const PORT = "";
const ROOT = null;

class StaticServer {
  constructor(port, root, opts) {
    switch (arguments.length) {
      case 3:
        this.port = `${port}` || PORT;
        this.root = root || ROOT;
        this.localOnly = (opts && opts.localOnly) || false;
        this.keepAlive = (opts && opts.keepAlive) || false;
        this.australiaKey = opts && opts.australiaKey;
        this.australiaPath = opts && opts.australiaPath;
        break;
      case 2:
        this.port = `${port}`;
        if (typeof arguments[1] === "string") {
          this.root = root;
          this.localOnly = false;
          this.keepAlive = false;
          this.australiaKey = "";
          this.australiaPath = "";
        } else {
          this.root = ROOT;
          this.localOnly = (arguments[1] && arguments[1].localOnly) || false;
          this.keepAlive = (arguments[1] && arguments[1].keepAlive) || false;

          this.australiaKey = (arguments[1] && arguments[1].australiaKey) || "";
          this.australiaPath =
            (arguments[1] && arguments[1].australiaPath) || "";
        }
        break;
      case 1:
        if (typeof arguments[0] === "number") {
          this.port = `${port}`;
          this.root = ROOT;
          this.localOnly = false;
          this.keepAlive = false;
          this.australiaKey = "";
          this.australiaPath = "";
        } else {
          this.port = PORT;
          this.root = ROOT;
          this.localOnly = (arguments[0] && arguments[0].localOnly) || false;
          this.keepAlive = (arguments[0] && arguments[0].keepAlive) || false;
          this.australiaKey = (arguments[0] && arguments[0].australiaKey) || "";
          this.australiaPath =
            (arguments[0] && arguments[0].australiaPath) || "";
        }
        break;
      default:
        this.port = PORT;
        this.root = ROOT;
        this.localOnly = false;
        this.keepAlive = false;
        this.australiaKey = "";
        this.australiaPath = "";
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

    return RNAustraliaWebServer.start(
      this.root,
      this.port,
      this.australiaKey,
      this.australiaPath,
      this.localOnly,
      this.keepAlive
    ).then((origin) => {
      this._origin = origin;
      return origin;
    });
  }

  stop() {
    this.running = false;

    return RNAustraliaWebServer.stop();
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
    return RNAustraliaWebServer.isRunning().then((running) => {
      this.running = running;

      return this.running;
    });
  }
}

export default StaticServer;
