part of game;

class PlayerControlSystem extends VoidEntitySystem {

  const int FORWARD = 38;
  const int TURN_LEFT= 37;
  const int TURN_RIGHT = 39;
  const int SHOOT = 32;
  final Map<int, bool> keyPressed = new Map<int, bool>();

  Velocity velocity;
  Transform transform;
  Weapon weapon;

  void initialize() {
    TagManager tm = world.getManager(new TagManager().runtimeType);
    Entity player = tm.getEntity(TAG_PLAYER);
    ComponentMapper<Velocity> vcm = new ComponentMapper<Velocity>(Velocity.type, world);
    ComponentMapper<Transform> tcm = new ComponentMapper<Transform>(Transform.type, world);
    ComponentMapper<Weapon> wcm = new ComponentMapper<Weapon>(Weapon.type, world);

    velocity = vcm.get(player);
    transform = tcm.get(player);
    weapon = wcm.get(player);

    window.on.keyDown.add(handleKeyDown);
    window.on.keyUp.add(handleKeyUp);
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
  }

  void recalcVelocity(double targetV) {
    if (transform.y > 0) {
      double diffX = targetV * TrigUtil.cos(transform.orientation) - velocity.x;
      double diffY = targetV * TrigUtil.sin(transform.orientation) - velocity.y;
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
    context.setTransform(1, 0, 0, 1, 0, 0);
    context.translate(-cameraTransform.x, MAX_HEIGHT/2);
    context..fillStyle = "blue"
        ..fillRect(cameraTransform.x, 0, MAX_WIDTH, MAX_HEIGHT/2)
        ..fillStyle = "lightblue"
        ..fillRect(cameraTransform.x, -MAX_HEIGHT/2, MAX_WIDTH, MAX_HEIGHT/2);
  }
}

class SpatialRenderingSystem extends EntityProcessingSystem {
  CanvasRenderingContext2D context;

  ComponentMapper<Transform> transformMapper;
  ComponentMapper<Spatial> spatialMapper;

  Transform cameraTransform;

  SpatialRenderingSystem(this.context) : super(Aspect.getAspectForAllOf(Spatial.type, [Transform.type]));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(Transform.type, world);
    spatialMapper = new ComponentMapper<Spatial>(Spatial.type, world);

    TagManager tagManager = world.getManager(new TagManager().runtimeType);
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    cameraTransform = transformMapper.get(camera);
  }

  void processEntity(Entity e) {
    Transform t = transformMapper.get(e);
    Spatial s = spatialMapper.get(e);

    num x = t.x;
    num y = t.y;
    double orientation = t.orientation;

    if (t.repeatsEveryX == 0) {
      drawSpatial(s, x, y, orientation);
    } else {
      int minFactor = (cameraTransform.x ~/ t.repeatsEveryX).toInt() - 1;
      int maxFactor = ((cameraTransform.x+MAX_WIDTH) ~/ t.repeatsEveryX).toInt() + 1;
      for (int i = minFactor; i < maxFactor; i++) {
        num offsetX = i * t.repeatsEveryX + x;
        drawSpatial(s, offsetX, y, orientation);
      }
    }
  }

  void drawSpatial(Spatial s, num x, num y, double orientation) {
    if (null == s.name) {
      context..fillStyle = "grey"
          ..fillRect(x, y, 5, 5);
    } else {
      ImageCache.withImage(s.name, (image) {
        context.save();
        try {
          context.translate(x, y);
          context.rotate(orientation);
          context.drawImage(image, -image.width/2, -image.height/2, image.width, image.height);
        } finally {
          context.restore();
        }
      });
    }
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
      shift = 3/8 * MAX_WIDTH * (0.2 + playerVelocity.x) / (1 + playerVelocity.x);
    } else if (playerVelocity.x < 0) {
      shift = - 3/8 * MAX_WIDTH * (-0.2 + playerVelocity.x) / (-1 + playerVelocity.x);
    }
    num diffX = playerTransform.x - (MAX_WIDTH/2 - shift) - cameraTransform.x;
    cameraTransform.x += 0.08 * diffX;
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
    if (t.y < 0) {
      v.y += 0.0005 * world.delta;
    } else {
      v.y *= 0.99;
    }
  }
}

class WeaponFiringSystem extends EntityProcessingSystem {
  ComponentMapper<Velocity> velocityMapper;
  ComponentMapper<Transform> transformMapper;
  ComponentMapper<Weapon> weaponMapper;

  WeaponFiringSystem() : super(Aspect.getAspectForAllOf(Weapon.type, [Transform.type, Velocity.type]));

  void initialize() {
    velocityMapper = new ComponentMapper<Velocity>(Velocity.type, world);
    transformMapper = new ComponentMapper<Transform>(Transform.type, world);
    weaponMapper = new ComponentMapper<Weapon>(Weapon.type, world);
  }

  void processEntity(Entity e) {
    Weapon w = weaponMapper.get(e);
    if (w.canShoot) {
      w.resetCooldown();
      Transform t = transformMapper.get(e);
      Velocity v = velocityMapper.get(e);

      Entity laser = world.createEntity();
      double offsetX = 13 * TrigUtil.sin(t.orientation) + 17 * TrigUtil.cos(t.orientation);
      double offsetY = - 13 * TrigUtil.cos(t.orientation) + 17 * TrigUtil.sin(t.orientation);
      laser.addComponent(new Transform(t.x + offsetX , t.y + offsetY, orientation: t.orientation) );
      laser.addComponent(new Velocity(x: v.x + 0.5*TrigUtil.cos(t.orientation), y: v.y+0.5*TrigUtil.sin(t.orientation)));
      laser.addComponent(new Spatial(name: 'laser.png'));
      laser.addComponent(new ExpirationTimer(1000));
      laser.addToWorld();
    } else if (w.cooldownTimer > 0){
      w.cooldownTimer -= world.delta;
    }
  }
}

class ExpirationSystem extends EntityProcessingSystem {
  ComponentMapper<ExpirationTimer> timerMapper;

  ExpirationSystem() : super(Aspect.getAspectForAllOf(ExpirationTimer.type));

  void initialize() {
    timerMapper = new ComponentMapper<ExpirationTimer>(ExpirationTimer.type, world);
  }

  void processEntity(Entity e) {
    ExpirationTimer timer = timerMapper.get(e);
    if (timer.expired) {
      e.deleteFromWorld();
    } else {
      timer.expireBy(world.delta);
    }
  }
}

class EntityTeleportationSystem extends EntityProcessingSystem {
  ComponentMapper<Transform> transformMapper;
  ComponentMapper<TeleportsOnTarget> teleportMapper;

  EntityTeleportationSystem() : super(Aspect.getAspectForAllOf(TeleportsOnTarget.type, [Transform.type]));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(Transform.type, world);
    teleportMapper = new ComponentMapper<TeleportsOnTarget>(TeleportsOnTarget.type, world);
  }

  void processEntity(Entity e) {
    Transform transform = transformMapper.get(e);
    TeleportsOnTarget teleport = teleportMapper.get(e);

    if (teleport.y > transform.y) {
      transform.y += teleport.by;
    }
  }

}