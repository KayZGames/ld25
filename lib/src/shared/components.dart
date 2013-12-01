part of shared;

class Transform extends Component {
  static Type get type => new Transform._hack().runtimeType;
  Transform._hack();
  Vector2 position;
  double _orientation;
  int repeatsEveryX;
  Transform(num x, num y, {num orientation : 0, this.repeatsEveryX: 0}) :
                            position = new Vector2(x.toDouble(), y.toDouble()) {
    _orientation = orientation.toDouble() % FastMath.PI;
  }

  set orientation(num value) => _orientation = value.toDouble() % FastMath.TWO_PI;
  double get orientation => _orientation;
  set x(num value) => position.x = value.toDouble();
  set y(num value) => position.y = value.toDouble();
  double get x => position.x;
  double get y => position.y;
}

class Velocity extends Component {
  static Type get type => new Velocity._hack().runtimeType;
  Velocity._hack();
  num x, y;
  num max;
  Velocity({this.x : 0, this.y: 0, this.max: 1});

  double get value => sqrt(x * x + y * y);
}

class Spatial extends Component {
  static Type get type => new Spatial._hack().runtimeType;
  Spatial._hack();
  String name;
  Spatial({this.name});
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
  double bulletSpeed;
  Weapon({this.cooldownTime : 1000, num bulletSpeed : 2}) : bulletSpeed = bulletSpeed.toDouble() {
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

class TeleportsOnTarget extends Component {
  static Type get type => new TeleportsOnTarget._hack().runtimeType;
  TeleportsOnTarget._hack();
  int y, by;
  TeleportsOnTarget(this.y, this.by);
}

class BodyDef extends Component {
  String bodyId;
  BodyDef(this.bodyId);
}

class Damage extends Component {
  int value;
  Damage(this.value);
}

class DamageOnCollision extends Component {
  int value;
  DamageOnCollision(this.value);
}

class Collision extends Component {}
class Destruction extends Component {}
class ImpactOnCollision extends Component {}
class DestroyOnCollision extends Component {}
class ExplosionOnDestruction extends Component {}