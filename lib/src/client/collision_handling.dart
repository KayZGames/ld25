part of client;


abstract class CollisionDetectionSystem extends VoidEntitySystem {
  ComponentMapper<Transform> tm;
  ComponentMapper<BodyDef> bm;
  ComponentMapper<DamageOnCollision> docm;
  Map<String, List<Polygon>> bodyDefs;
  bool collisions = false;

  PlayerManager pm;
  GroupManager gm;

  CollisionDetectionSystem(this.bodyDefs);

  void initialize() {
    tm = new ComponentMapper<Transform>(Transform, world);
    bm = new ComponentMapper<BodyDef>(BodyDef, world);
    docm = new ComponentMapper<DamageOnCollision>(DamageOnCollision, world);
    pm = world.getManager(PlayerManager);
    gm = world.getManager(GroupManager);
  }

  void begin() {
    collisions = false;
  }

  void end() {
    if (collisions) {
      world.processEntityChanges();
    }
  }

  void processCollisions(ReadOnlyBag<Entity> units, ReadOnlyBag<Entity> bullets) {
    int size = units.size;
    if (size > 1) {
      for (int i = 0; i < units.size; i++) {
        for (int j = 0; j < bullets.size; j++) {
          var unit = units[i];
          var bullet = bullets[j];

          var t1 = tm.get(unit);
          var t2 = tm.get(bullet);

          var pos1 = t1.position;
          var pos2 = t2.position;

          var rotation1 = t1.rotation;
          var rotation2 = t2.rotation;

          var bodyId1 = bm.get(unit).bodyId;
          var bodyId2 = bm.get(bullet).bodyId;

          var shapes1 = bodyDefs[bodyId1];
          var shapes2 = bodyDefs[bodyId2];

          if (doShapesCollide(shapes1, pos1, rotation1, shapes2, pos2, rotation2)) {
            unit.addComponent(new Collision(pos2.x, pos2.y));
            bullet.addComponent(new Collision(pos1.x, pos1.y));
            transferDamage(unit, bullet);
            transferDamage(bullet, unit);
            unit.changedInWorld();
            bullet.changedInWorld();
            collisions = true;
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

  bool doShapesCollide(List<Polygon> shapes1, Vector2 pos1, Matrix2 rotation1, List<Polygon> shapes2, Vector2 pos2, Matrix2 rotation2) {
    bool shapeCollides = true;
    shapes2.forEach((shape2) {
      shapeCollides = false;
      shapes1.where((_) => !shapeCollides).forEach((shape1) {
        shapeCollides = true;
        var currentVertex1 = rotate(pos1, shape1.vertices.last, rotation1);

        shape1.vertices.forEach((vertex1) {
          var nextVertex1 = rotate(pos1, vertex1, rotation1);
          var normal = getNormal(currentVertex1, nextVertex1);

          double min1 = nextVertex1.dot(normal);
          double max1 = min1;
          shape1.vertices.sublist(1).forEach((projectedVertex1) {
            var dot = rotate(pos1, projectedVertex1, rotation1).dot(normal);
            min1 = min(min1, dot);
            max1 = max(max1, dot);
          });

          double min2;
          double max2;
          bool collides = true;
          shape2.vertices.forEach((projectedVertex2) {
            var dot = rotate(pos2, projectedVertex2, rotation2).dot(normal);
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
          currentVertex1 = nextVertex1;
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

class ComputerCollisionDetectionSystem extends CollisionDetectionSystem {
  ComputerCollisionDetectionSystem(Map<String, List<Polygon>> bodyDefs) : super(bodyDefs);

  void processSystem() {
    var units = pm.getEntitiesOfPlayer(PLAYER_COMPUTER);
    var bullets = gm.getEntities(GROUP_HUMAN_WEAPON);
    processCollisions(units, bullets);
  }
}

class HumanCollisionDetectionSystem extends CollisionDetectionSystem {
  HumanCollisionDetectionSystem(Map<String, List<Polygon>> bodyDefs) : super(bodyDefs);

  void processSystem() {
    var units = pm.getEntitiesOfPlayer(PLAYER_HUMAN);
    var bullets = gm.getEntities(GROUP_COMPUTER_WEAPON);
    processCollisions(units, bullets);
  }
}

class DestroyOnCollisionSystem extends EntityProcessingSystem {
  DestroyOnCollisionSystem() : super(Aspect.getAspectForAllOf([Collision, DestroyOnCollision]));

  void processEntity(Entity entity) {
    entity.deleteFromWorld();
  }
}

class CollisionCleanupSystem extends EntityProcessingSystem {
  CollisionCleanupSystem() : super(Aspect.getAspectForAllOf([Collision]));

  void processEntity(Entity entity) {
    entity.removeComponent(Collision);
    entity.changedInWorld();
  }
}


class ExplosionOnCollisionSystem extends EntityProcessingSystem {
  ComponentMapper<ExplosionOnCollision> em;
  ComponentMapper<Velocity> vm;
  ComponentMapper<Collision> cm;

  ExplosionOnCollisionSystem() : super(Aspect.getAspectForAllOf([Collision, ExplosionOnCollision, Velocity]));

  void initialize() {
    em = new ComponentMapper<ExplosionOnCollision>(ExplosionOnCollision, world);
    vm = new ComponentMapper<Velocity>(Velocity, world);
    cm = new ComponentMapper<Collision>(Collision, world);
  }

  void processEntity(Entity entity) {
    var e = em.get(entity);
    var c = cm.get(entity);
    var v = vm.get(entity);
    for (int i = 0; i < e.explosions * 3; i++) {
      var explosion = world.createEntity();
      explosion.addComponent(new Spatial(name: '${e.effect}_${random.nextInt(4)}.png'));
      explosion.addComponent(new Transform(c.x, c.y));
      explosion.addComponent(new Velocity(x: v.x * 0.9, y: v.y * 0.9));
      explosion.addComponent(new ExpirationTimer(50 + random.nextDouble() * 150));
      explosion.addToWorld();
    }
  }
}


class ExplosionOnDestructionSystem extends EntityProcessingSystem {
  ComponentMapper<ExplosionOnDestruction> em;
  ComponentMapper<Velocity> vm;
  ComponentMapper<Transform> tm;
  ComponentMapper<BodyDef> bm;
  Map<String, List<Polygon>> bodyDefs;

  ExplosionOnDestructionSystem(this.bodyDefs) : super(Aspect.getAspectForAllOf([Transform, BodyDef, Destruction, ExplosionOnDestruction, Velocity]));

  void initialize() {
    em = new ComponentMapper<ExplosionOnDestruction>(ExplosionOnDestruction, world);
    vm = new ComponentMapper<Velocity>(Velocity, world);
    tm = new ComponentMapper<Transform>(Transform, world);
    bm = new ComponentMapper<BodyDef>(BodyDef, world);
  }

  void processEntity(Entity entity) {
    var e = em.get(entity);
    var v = vm.get(entity);
    var b = bm.get(entity);
    var t = tm.get(entity);
    var polys = bodyDefs[b.bodyId];
    for (int i = 0; i < e.explosions * 3; i++) {
      var explosion = world.createEntity();
      explosion.addComponent(new Spatial(name: '${e.effect}_${random.nextInt(4)}.png'));
      var poly = polys[random.nextInt(polys.length)];
      var vertex = poly.vertices[random.nextInt(poly.vertices.length)];
      var pos = rotate(t.position, vertex, t.rotation);
      explosion.addComponent(new Transform(pos.x, pos.y));
      explosion.addComponent(new Velocity(x: v.x * 0.9, y: v.y * 0.9));
      explosion.addComponent(new ExpirationTimer(50 + random.nextDouble() * 250));
      explosion.addToWorld();
    }
  }
}