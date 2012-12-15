part of game;

class PlayerControlSystem extends VoidEntitySystem {

  const int FORWARD = 38;
  const int TURN_RIGHT = 37;
  const int TURN_LEFT = 39;
  final Map<int, bool> keyPressed = new Map<int, bool>();

  Velocity velocity;
  Transform transform;

  void initialize() {
    TagManager tm = world.getManager(new TagManager().runtimeType);
    Entity player = tm.getEntity(TAG_PLAYER);
    var vcm = new ComponentMapper<Velocity>(Velocity.type, world);
    var tcm = new ComponentMapper<Transform>(Transform.type, world);
    velocity = vcm.get(player);
    transform = tcm.get(player);

    window.on.keyDown.add(handleKeyDown);
    window.on.keyUp.add(handleKeyUp);
  }

  void processSystem() {
    if (keyPressed[FORWARD] == true) {
      velocity.value += 0.01;
    }
    if (keyPressed[TURN_RIGHT] == true) {
      transform.orientation -= 0.02;
    }
    if (keyPressed[TURN_LEFT] == true) {
      transform.orientation += 0.02;
    }
  }

  void handleKeyDown(KeyboardEvent e) {
    keyPressed[e.keyCode] = true;
  }

  void handleKeyUp(KeyboardEvent e) {
    keyPressed[e.keyCode] = false;
  }
}

class MovementSystem extends EntityProcessingSystem {
  ComponentMapper<Transform> transformMapper;
  ComponentMapper<Velocity> velocityMapper;

  MovementSystem() : super(Aspect.getAspectForAllOf(Transform.type, [Velocity.type]));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(Transform.type, world);
    velocityMapper = new ComponentMapper<Velocity>(Velocity.type, world);
  }

  void processEntity(Entity e) {
    var t = transformMapper.get(e);
    var v = velocityMapper.get(e);

    t.x += world.delta * v.value * TrigUtil.sin(t.orientation);
    t.y += world.delta * v.value * TrigUtil.cos(t.orientation);
  }
}

class BackgroundRenderingSystem extends VoidEntitySystem {
  Transform cameraTransform;

  CanvasRenderingContext2D context;

  BackgroundRenderingSystem(this.context);

  void initialize() {
    ComponentMapper<Transform> transformMapper = new ComponentMapper<Transform>(Transform.type, world);
    TagManager tagManager = world.getManager(new TagManager().runtimeType);

    Entity camera = tagManager.getEntity(TAG_CAMERA);

    cameraTransform = transformMapper.get(camera);
  }

  void processSystem() {
    context.setTransform(1, 0, 0, -1, 0, 0);
    context.translate(-cameraTransform.x, -MAX_HEIGHT/2);
    context..fillStyle = "blue"
        ..fillRect(cameraTransform.x, -MAX_HEIGHT/2, MAX_WIDTH, MAX_HEIGHT/2)
        ..fillStyle = "lightblue"
        ..fillRect(cameraTransform.x, 0, MAX_WIDTH, MAX_HEIGHT/2);
  }
}

class SpatialRenderingSystem extends EntityProcessingSystem {
  CanvasRenderingContext2D context;

  ComponentMapper<Transform> transformMapper;
  ComponentMapper<Spatial> spatialMapper;

  SpatialRenderingSystem(this.context) : super(Aspect.getAspectForAllOf(Spatial.type, [Transform.type]));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(Transform.type, world);
    spatialMapper = new ComponentMapper<Spatial>(Spatial.type, world);
  }

  void processEntity(Entity e) {
    Transform t = transformMapper.get(e);

    context..fillStyle = "grey"
        ..fillRect(t.x, t.y, 5, 5);

  }
}

class CameraSystem extends VoidEntitySystem {
  Transform playerTransform;
  Transform cameraTransform;

  CameraSystem();

  void initialize() {
    ComponentMapper<Transform> transformMapper = new ComponentMapper<Transform>(Transform.type, world);
    TagManager tagManager = world.getManager(new TagManager().runtimeType);

    Entity player = tagManager.getEntity(TAG_PLAYER);
    Entity camera = tagManager.getEntity(TAG_CAMERA);

    playerTransform = transformMapper.get(player);
    cameraTransform = transformMapper.get(camera);
  }

  void processSystem() {
    cameraTransform.x = playerTransform.x - MAX_WIDTH ~/ 8;
  }
}