part of client;

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
  PlayerManager pm;
  GroupManager gm;

  WeaponFiringSystem() : super(Aspect.getAspectForAllOf([Weapon, Transform, Velocity]));

  void initialize() {
    velocityMapper = new ComponentMapper<Velocity>(Velocity, world);
    transformMapper = new ComponentMapper<Transform>(Transform, world);
    weaponMapper = new ComponentMapper<Weapon>(Weapon, world);
    pm = world.getManager(PlayerManager);
    gm = world.getManager(GroupManager);
  }

  void processEntity(Entity e) {
    Weapon w = weaponMapper.get(e);
    if (w.canShoot) {
      w.resetCooldown();
      Transform t = transformMapper.get(e);
      Velocity v = velocityMapper.get(e);

      Entity laser = world.createEntity();
      double offsetX = 13 * t.rotation.entry(1, 0) + 17 * t.rotation.entry(0, 0);
      double offsetY = - 13 * t.rotation.entry(0, 0) + 17 * t.rotation.entry(1, 0);
      double speed = w.bulletSpeed;
      laser.addComponent(new Transform(t.x + offsetX , t.y + offsetY, rotation: t.rotation) );
      laser.addComponent(new Velocity(x: v.x + speed * t.rotation.entry(0, 0), y: v.y + speed * t.rotation.entry(1, 0)));
      laser.addComponent(new Spatial(name: 'laser.png'));
      laser.addComponent(new ExpirationTimer(1000));
      laser.addComponent(new BodyDef('laser'));
      laser.addComponent(new DestroyOnCollision());
      laser.addComponent(new DamageOnCollision(w.bulletDamage));
      laser.addToWorld();
      gm.add(laser, '${pm.getPlayer(e)}_bullet');
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
      if (teleport.sound != null) {
        var e = world.createEntity();
        e.addComponent(new Sound(teleport.sound));
        e.addToWorld();
      }
    }
  }

  bool checkProcessing() => super.checkProcessing() && state.running;
}

class DeathTollSystem extends EntityProcessingSystem {
  ComponentMapper<BodyCount> bcm;

  DeathTollSystem() : super(Aspect.getAspectForAllOf([BodyCount, Destruction]));

  void initialize() {
    bcm = new ComponentMapper<BodyCount>(BodyCount, world);
  }

  void processEntity(Entity entity) {
    var bc = bcm.get(entity);
    state.deathToll += bc.value;
  }
}

class DamageToHealthSystem extends EntityProcessingSystem {
  ComponentMapper<Health> hm;
  ComponentMapper<Damage> dm;
  DamageToHealthSystem() : super(Aspect.getAspectForAllOf([Health, Damage]));

  void initialize() {
    hm = new ComponentMapper<Health>(Health, world);
    dm = new ComponentMapper<Damage>(Damage, world);
  }

  void processEntity(Entity entity) {
    var h = hm.get(entity);
    var d = dm.get(entity);

    h.currentHealth -= d.value;

    entity.removeComponent(Damage);
    if (h.currentHealth <= 0) {
      entity.addComponent(new Destruction());
    }
    entity.changedInWorld();
  }
}

class DestructionSystem extends EntityProcessingSystem {
  DestructionSystem() : super(Aspect.getAspectForAllOf([Destruction]));
  void processEntity(Entity entity) => entity.deleteFromWorld();
}