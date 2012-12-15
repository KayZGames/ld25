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
      if (transform.y < 0) {
        num untilMaxVelocity = velocity.max - FastMath.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
        velocity.x += 0.01 * TrigUtil.sin(transform.orientation) * untilMaxVelocity;
        velocity.y += 0.01 * TrigUtil.cos(transform.orientation) * untilMaxVelocity;
      }
    } else {
      velocity.x *= 0.995;
      velocity.y *= 0.995;
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

    t.x += world.delta * v.x;
    t.y += world.delta * v.y;
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
  Velocity playerVelocity;
  Transform cameraTransform;

  CameraSystem();

  void initialize() {
    ComponentMapper<Transform> transformMapper = new ComponentMapper<Transform>(Transform.type, world);
    ComponentMapper<Velocity> velocityMapper = new ComponentMapper<Velocity>(Velocity.type, world);
    TagManager tagManager = world.getManager(new TagManager().runtimeType);

    Entity player = tagManager.getEntity(TAG_PLAYER);
    Entity camera = tagManager.getEntity(TAG_CAMERA);

    playerTransform = transformMapper.get(player);
    playerVelocity = velocityMapper.get(player);
    cameraTransform = transformMapper.get(camera);
  }

  void processSystem() {
    double shift = 0.0;
    if (playerVelocity.x > 0) {
      shift = 3/8 * MAX_WIDTH * playerVelocity.x / (1 + playerVelocity.x);
    } else if (playerVelocity.x < 0) {
      shift = - 3/8 * MAX_WIDTH * playerVelocity.x / (-1 + playerVelocity.x);
    }
    cameraTransform.x = playerTransform.x - (MAX_WIDTH/2 - shift);
  }
}

class GravitationSystem extends EntityProcessingSystem {
  ComponentMapper<Velocity> velocityMapper;
  ComponentMapper<Transform> transformMapper;

  GravitationSystem() : super(Aspect.getAspectForAllOf(Mass.type, [Velocity.type, Transform.type]));

  void initialize() {
    velocityMapper = new ComponentMapper<Velocity>(Velocity.type, world);
    transformMapper = new ComponentMapper<Transform>(Transform.type, world);
  }

  void processEntity(Entity e) {
    var t = transformMapper.get(e);
    var v = velocityMapper.get(e);
    if (t.y > 0) {
      v.y -= 0.0005 * world.delta;
    } else {
      v.y *= 0.99;
    }
  }
}