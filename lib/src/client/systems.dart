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
      double diffX = targetV * FastMath.cos(transform.orientation) - velocity.x;
      double diffY = targetV * FastMath.sin(transform.orientation) - velocity.y;
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

class MovementSystem extends EntityProcessingSystem {
  ComponentMapper<Transform> transformMapper;
  ComponentMapper<Velocity> velocityMapper;

  MovementSystem() : super(Aspect.getAspectForAllOf([Transform, Velocity]));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(Transform, world);
    velocityMapper = new ComponentMapper<Velocity>(Velocity, world);
  }

  void processEntity(Entity e) {
    var t = transformMapper.get(e);
    var v = velocityMapper.get(e);

    t.x += world.delta * v.x;
    t.y += world.delta * v.y;
  }

  bool checkProcessing() => super.checkProcessing() && state.running;
}

class BackgroundRenderingSystem extends VoidEntitySystem {
  Transform cameraTransform;

  CanvasRenderingContext2D context;

  BackgroundRenderingSystem(this.context);

  void initialize() {
    ComponentMapper<Transform> transformMapper = new ComponentMapper<Transform>(Transform.type, world);
    TagManager tagManager = world.getManager(TagManager);

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

class ForegroundRenderingSystem extends BackgroundRenderingSystem {
  ForegroundRenderingSystem(context) : super(context);

  void processSystem() {
    context.save();
    try {
      context.globalAlpha = 0.25;
      context..fillStyle = "blue"
          ..fillRect(cameraTransform.x, 0, MAX_WIDTH, MAX_HEIGHT/2);;
    } finally {
      context.restore();
    }
  }
}

class SpatialRenderingSystem extends EntityProcessingSystem {
  CanvasRenderingContext2D context;
  SpriteSheet spriteSheet;

  ComponentMapper<Transform> transformMapper;
  ComponentMapper<Spatial> spatialMapper;

  Transform cameraTransform;

  SpatialRenderingSystem(this.context, this.spriteSheet) : super(Aspect.getAspectForAllOf([Spatial, Transform]));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(Transform, world);
    spatialMapper = new ComponentMapper<Spatial>(Spatial, world);

    TagManager tagManager = world.getManager(TagManager);
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
      context.save();
      try {
        context.translate(x, y);
        context.rotate(orientation);
        var sprite = spriteSheet[s.name];
        context.drawImageToRect(spriteSheet.image, sprite.dst, sourceRect: sprite.src);
      } finally {
        context.restore();
      }
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

  bool checkProcessing() => super.checkProcessing() && state.running;
}

class GravitationSystem extends EntityProcessingSystem {
  ComponentMapper<Velocity> velocityMapper;
  ComponentMapper<Transform> transformMapper;

  GravitationSystem() : super(Aspect.getAspectForAllOf([Mass, Velocity, Transform]));

  void initialize() {
    velocityMapper = new ComponentMapper<Velocity>(Velocity, world);
    transformMapper = new ComponentMapper<Transform>(Transform, world);
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

  bool checkProcessing() => super.checkProcessing() && state.running;
}

class WeaponFiringSystem extends EntityProcessingSystem {
  ComponentMapper<Velocity> velocityMapper;
  ComponentMapper<Transform> transformMapper;
  ComponentMapper<Weapon> weaponMapper;

  WeaponFiringSystem() : super(Aspect.getAspectForAllOf([Weapon, Transform, Velocity]));

  void initialize() {
    velocityMapper = new ComponentMapper<Velocity>(Velocity, world);
    transformMapper = new ComponentMapper<Transform>(Transform, world);
    weaponMapper = new ComponentMapper<Weapon>(Weapon, world);
  }

  void processEntity(Entity e) {
    Weapon w = weaponMapper.get(e);
    if (w.canShoot) {
      w.resetCooldown();
      Transform t = transformMapper.get(e);
      Velocity v = velocityMapper.get(e);

      Entity laser = world.createEntity();
      double offsetX = 13 * FastMath.sin(t.orientation) + 17 * FastMath.cos(t.orientation);
      double offsetY = - 13 * FastMath.cos(t.orientation) + 17 * FastMath.sin(t.orientation);
      double speed = w.bulletSpeed;
      laser.addComponent(new Transform(t.x + offsetX , t.y + offsetY, orientation: t.orientation) );
      laser.addComponent(new Velocity(x: v.x + speed * FastMath.cos(t.orientation), y: v.y + speed * FastMath.sin(t.orientation)));
      laser.addComponent(new Spatial(name: 'laser.png'));
      laser.addComponent(new ExpirationTimer(1000));
      laser.addComponent(new BodyDef('laser'));
      laser.addComponent(new DestroyOnCollision());
      laser.addToWorld();
      Entity laserSound = world.createEntity();
      laserSound.addComponent(new Sound('laser_shoot'));
      laserSound.addToWorld();
    } else if (w.cooldownTimer > 0){
      w.cooldownTimer -= world.delta;
    }
  }

  bool checkProcessing() => super.checkProcessing() && state.running;
}

class ExpirationSystem extends EntityProcessingSystem {
  ComponentMapper<ExpirationTimer> timerMapper;

  ExpirationSystem() : super(Aspect.getAspectForAllOf([ExpirationTimer]));

  void initialize() {
    timerMapper = new ComponentMapper<ExpirationTimer>(ExpirationTimer, world);
  }

  void processEntity(Entity e) {
    ExpirationTimer timer = timerMapper.get(e);
    if (timer.expired) {
      e.deleteFromWorld();
    } else {
      timer.expireBy(world.delta);
    }
  }

  bool checkProcessing() => super.checkProcessing() && state.running;
}

class EntityTeleportationSystem extends EntityProcessingSystem {
  ComponentMapper<Transform> transformMapper;
  ComponentMapper<TeleportsOnTarget> teleportMapper;

  EntityTeleportationSystem() : super(Aspect.getAspectForAllOf([TeleportsOnTarget, Transform]));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(Transform, world);
    teleportMapper = new ComponentMapper<TeleportsOnTarget>(TeleportsOnTarget, world);
  }

  void processEntity(Entity e) {
    Transform transform = transformMapper.get(e);
    TeleportsOnTarget teleport = teleportMapper.get(e);

    if (teleport.y > transform.y) {
      transform.y += teleport.by;
    }
  }

  bool checkProcessing() => super.checkProcessing() && state.running;
}

class BufferToCanvasSystem extends VoidEntitySystem {
  CanvasElement buffer;
  CanvasRenderingContext2D ctx;

  BufferToCanvasSystem(this.buffer, this.ctx);

  void processSystem() {
    ctx.drawImage(buffer, 0, 0);
  }
}

class MenuSystem extends VoidEntitySystem {
  CanvasElement canvas;
  CanvasRenderingContext2D ctx;
  CanvasQuery startMenu, pauseMenu;
  MenuSystem(CanvasElement canvas) : canvas = canvas,
                                                 ctx = canvas.context2D;

  void initialize() {
    startMenu = _createMenu('Start');
    pauseMenu = _createMenu('Resume');
    var button = _getButton();
    cq(canvas).framework.onMouseDown.listen((event) {
      if (button.containsPoint(event.position)) {
        state.started = true;
        state.paused = false;
      }
    });
  }

  CanvasQuery _createMenu(String buttonText) {
    var menu = cq(MAX_WIDTH, MAX_HEIGHT);
    menu..textBaseline = 'top'
        ..font = '12px Verdana';
    var bounds = menu.textBoundaries(buttonText);
    var button = _getButton();
    menu..roundRect(20, 20, MAX_WIDTH - 40, MAX_HEIGHT - 40, 20, strokeStyle: 'black', fillStyle: 'blue')
        ..roundRect(button.left, button.top, button.width, button.height, 10, strokeStyle: 'red', fillStyle: 'green')
        ..fillText(buttonText, MAX_WIDTH ~/ 2 - bounds.width ~/ 2, MAX_HEIGHT ~/2 - bounds.height ~/ 2);
    return menu;
  }

  Rectangle _getButton() {
    var buttonLeft = MAX_WIDTH ~/ 2 - 50;
    var buttonTop = MAX_HEIGHT ~/2 - 15;
    var buttonWidth = 100;
    var buttonHeight = 30;
    return new Rectangle(buttonLeft, buttonTop, buttonWidth, buttonHeight);
  }

  void processSystem() {
    if (state.paused) {
      ctx.drawImage(pauseMenu.canvas, 0, 0);
    } else {
      ctx.drawImage(startMenu.canvas, 0, 0);
    }
  }

  bool checkProcessing() => super.checkProcessing() && !state.running;
}

class CollisionDetectionSystem extends EntitySystem {
  ComponentMapper<Transform> tm;
  ComponentMapper<BodyDef> bm;
  ComponentMapper<DamageOnCollision> docm;
  Map<String, List<Polygon>> bodyDefs;

  CollisionDetectionSystem(this.bodyDefs) : super(Aspect.getAspectForAllOf([Transform, BodyDef]));

  void initialize() {
    tm = new ComponentMapper<Transform>(Transform, world);
    bm = new ComponentMapper<BodyDef>(BodyDef, world);
    docm = new ComponentMapper<DamageOnCollision>(DamageOnCollision, world);
  }

  void processEntities(ReadOnlyBag<Entity> entities) {
    int size = entities.size;
    if (size > 1) {
      for (int i = 0; i < entities.size - 1; i++) {
        for (int j = i + 1; j < entities.size; j++) {
          var entity1 = entities[i];
          var entity2 = entities[j];

          var pos1 = tm.get(entity1).position;
          var pos2 = tm.get(entity2).position;

          var bodyId1 = bm.get(entity1).bodyId;
          var bodyId2 = bm.get(entity2).bodyId;

          var shapes1 = bodyDefs[bodyId1];
          var shapes2 = bodyDefs[bodyId2];

          if (doShapesCollide(shapes1, pos1, shapes2, pos2)) {
            entity1.addComponent(new Collision());
            entity2.addComponent(new Collision());
            transferDamage(entity1, entity2);
            transferDamage(entity2, entity1);
            entity1.changedInWorld();
            entity2.changedInWorld();
          }
        }
      }
    }
  }

  void transferDamage(entity1, entity2) {
    var dmg = docm.getSafe(entity1);
    if (null != dmg) {
      entity2.addComponent(new Damage(dmg.value));
    }
  }

  bool doShapesCollide(List<Polygon> shapes1, Vector2 pos1, List<Polygon> shapes2, Vector2 pos2) {
    bool shapeCollides = true;
    shapes2.forEach((shape2) {
      shapeCollides = false;
      shapes1.where((_) => !shapeCollides).forEach((shape1) {
        shapeCollides = true;
        var currentVertex1 = shape1.vertices.last;

        shape1.vertices.forEach((vertex1) {
          var normal = getNormal(currentVertex1 + pos1, vertex1 + pos1);

          double min1 = (vertex1 + pos1).dot(normal);
          double max1 = min1;
          shape1.vertices.sublist(1).forEach((projectedVertex1) {
            var dot = (projectedVertex1 + pos1).dot(normal);
            min1 = min(min1, dot);
            max1 = max(max1, dot);
          });

          double min2;
          double max2;
          bool collides = true;
          shape2.vertices.forEach((projectedVertex2) {
            var dot = (projectedVertex2 + pos2).dot(normal);
            if (null == min2) {
              min2 = dot;
              max2 = dot;
            }
            min2 = min(min2, dot);
            max2 = max(max2, dot);
          });
          if (max1 < min2 || min1 > max2) {
            shapeCollides = false;
            return;
          }
          currentVertex1 = vertex1;
        });
        if (shapeCollides) {
          return;
        }
      });
      if (shapeCollides) {
        return;
      }
    });
    return shapeCollides;
  }

  Vector2 getNormal(Vector2 vertext1, Vector2 vertex2) {
    var normal = new Vector2(- vertext1.y + vertex2.y, vertext1.x - vertex2.x);
    normal.normalize();
    return normal;
  }

  bool checkProcessing() => true;
}

class DestroyOnCollisionSystem extends EntityProcessingSystem {
  DestroyOnCollisionSystem() : super(Aspect.getAspectForAllOf([Collision, DestroyOnCollision]));

  void processEntity(Entity entity) {
    entity.deleteFromWorld();
  }
}