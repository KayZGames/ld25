part of game;

class Transform extends Component {
  static Type get type => new Transform._hack().runtimeType;
  Transform._hack();
  num x, y;
  double _orientation;
  Transform(this.x, this.y, {num orientation : 0}) {
    _orientation = orientation.toDouble() % FastMath.PI;
  }

  set orientation(num value) => _orientation = value.toDouble() % FastMath.TWO_PI;
  double get orientation => _orientation;
}

class Velocity extends Component {
  static Type get type => new Velocity._hack().runtimeType;
  Velocity._hack();
  num x, y;
  num max;
  Velocity({this.x : 0, this.y: 0, this.max: 1});
}

class Spatial extends Component {
  static Type get type => new Spatial._hack().runtimeType;
  Spatial._hack();
  Spatial();
}

class Mass extends Component {
  static Type get type => new Mass._hack().runtimeType;
  Mass._hack();
  Mass();
}

class Weapon extends Component {
  static Type get type => new Weapon._hack().runtimeType;
  Weapon._hack();
  bool shoot = false;
  num cooldownTimer = 0;
  num cooldownTime;
  Weapon({this.cooldownTime : 1000}) {
    cooldownTimer = 1000;
  }

  bool get canShoot {
    if (shoot && cooldownTimer <= 0) return true;
    return false;
  }

  void resetCooldown() {
    cooldownTimer = cooldownTime;
  }
}

class ExpirationTimer extends Component {
  static Type get type => new ExpirationTimer._hack().runtimeType;
  ExpirationTimer._hack();
  num maxTime, timeLeft;
  ExpirationTimer(this.maxTime) {
    timeLeft = maxTime;
  }

  void expireBy(num delta) {
    timeLeft -= delta;
    if (expired) {
      timeLeft = 0;
    }
  }
  bool get expired => timeLeft <= 0;
}