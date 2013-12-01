part of client;

class PlayerControlSystem extends VoidEntitySystem {

  static const int FORWARD = KeyCode.UP;
  static const int TURN_LEFT= KeyCode.LEFT;
  static const int TURN_RIGHT = KeyCode.RIGHT;
  static const int SHOOT = KeyCode.SPACE;
  static const int PAUSE1 = KeyCode.PAUSE;
  static const int PAUSE2 = KeyCode.P;
  final Map<int, bool> keyPressed = new Map<int, bool>();

  Velocity velocity;
  Transform transform;
  Weapon weapon;

  void initialize() {
    TagManager tm = world.getManager(new TagManager().runtimeType);
    Entity player = tm.getEntity(TAG_PLAYER);
    ComponentMapper<Velocity> vcm = new ComponentMapper<Velocity>(Velocity, world);
    ComponentMapper<Transform> tcm = new ComponentMapper<Transform>(Transform, world);
    ComponentMapper<Weapon> wcm = new ComponentMapper<Weapon>(Weapon, world);

    velocity = vcm.get(player);
    transform = tcm.get(player);
    weapon = wcm.get(player);

    window.onKeyDown.listen(handleKeyDown);
    window.onKeyUp.listen(handleKeyUp);
  }

  void processSystem() {
    if (keyPressed[FORWARD] == true) {
      if (transform.y > 0) {
        num untilMaxVelocity = velocity.max - velocity.value;
        recalcVelocity(velocity.value + 0.1 * untilMaxVelocity);
      }
    } else {
      velocity.x *= 0.995;
      velocity.y *= 0.995;
    }
    if (keyPressed[TURN_RIGHT] == true) {
      transform.orientation += 0.02;
      recalcVelocity(velocity.value);
    }
    if (keyPressed[TURN_LEFT] == true) {
      transform.orientation -= 0.02;
      recalcVelocity(velocity.value);
    }
    if (keyPressed[SHOOT] == true) {
      weapon.shoot = true;
    } else {
      weapon.shoot = false;
    }
    if (keyPressed[PAUSE1] == true || keyPressed[PAUSE2] == true) {
      state.paused = true;
    }
  }

  void recalcVelocity(double targetV) {
    if (transform.y > 0) {
      double diffX = targetV * transform.rotation.entry(0, 0) - velocity.x;
      double diffY = targetV * transform.rotation.entry(1, 0) - velocity.y;
      velocity.x += diffX * 0.1;
      velocity.y += diffY * 0.1;
    }
  }

  void handleKeyDown(KeyboardEvent e) {
    keyPressed[e.keyCode] = true;
  }

  void handleKeyUp(KeyboardEvent e) {
    keyPressed[e.keyCode] = false;
  }

  bool checkProcessing() => super.checkProcessing() && state.running;
}