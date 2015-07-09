part of client;

class PlayerControlSystem extends GenericInputHandlingSystem {
  static const int FORWARD = KeyCode.UP;
  static const int TURN_LEFT = KeyCode.LEFT;
  static const int TURN_RIGHT = KeyCode.RIGHT;
  static const int SHOOT = KeyCode.SPACE;
  static const int PAUSE1 = KeyCode.PAUSE;
  static const int PAUSE2 = KeyCode.P;

  Velocity velocity;
  Transform transform;
  Weapon weapon;

  PlayerControlSystem() : super(Aspect.getAspectForAllOf([Controller]));

  void initialize() {
    super.initialize();
    TagManager tm = world.getManager(new TagManager().runtimeType);
    Entity player = tm.getEntity(TAG_PLAYER);
    Mapper<Velocity> vcm = new Mapper<Velocity>(Velocity, world);
    Mapper<Transform> tcm = new Mapper<Transform>(Transform, world);
    Mapper<Weapon> wcm = new Mapper<Weapon>(Weapon, world);

    velocity = vcm[player];
    transform = tcm[player];
    weapon = wcm[player];
  }

  void recalcVelocity(double targetV) {
    if (transform.y > 0) {
      double diffX = targetV * transform.rotation.entry(0, 0) - velocity.x;
      double diffY = targetV * transform.rotation.entry(1, 0) - velocity.y;
      velocity.x += diffX * 0.1;
      velocity.y += diffY * 0.1;
    }
  }

  bool checkProcessing() => super.checkProcessing() && state.running;

  @override
  void processEntity(Entity entity) {

    if (up) {
      if (transform.y > 0) {
        num untilMaxVelocity = velocity.max - velocity.value;
        recalcVelocity(velocity.value + 0.1 * untilMaxVelocity);
      }
    } else {
      velocity.x *= 0.995;
      velocity.y *= 0.995;
    }
    if (right) {
      transform.orientation += 0.02;
      recalcVelocity(velocity.value);
    }
    if (left) {
      transform.orientation -= 0.02;
      recalcVelocity(velocity.value);
    }
    if (isPressed(SHOOT)) {
      weapon.shoot = true;
    } else {
      weapon.shoot = false;
    }
    if (isPressed(PAUSE1) || isPressed(PAUSE2)) {
      state.paused = true;
    }
  }
}
