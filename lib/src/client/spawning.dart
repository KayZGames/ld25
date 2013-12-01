part of client;

abstract class Spawner extends VoidEntitySystem {
  Transform pt;

  void initialize() {
    TagManager tag = world.getManager(new TagManager().runtimeType);
    Entity player = tag.getEntity(TAG_PLAYER);
    var tm = new ComponentMapper<Transform>(Transform, world);
    pt = tm.get(player);
  }

  Entity addEntity(List<Component> components) {
    var entity = world.createEntity();
    components.forEach((component) => entity.addComponent(component));
    entity.addToWorld();
    return entity;
  }

  bool checkProcessing() => random.nextDouble() < chance;

  double get chance;
}

class AirplaneSpawner extends Spawner {

  void processSystem() {
    addEntity([new Transform(pt.x - MAX_WIDTH * 2, (-3.5 + random.nextDouble() * 1) * MAX_HEIGHT/8, orientation: 0),
               new Velocity(x: 0.3 + random.nextDouble() * 0.4),
               new Spatial(name: 'airplane.png'),
               new BodyDef('airplane'),
               new Health(5),
               new BodyCount(150),
               new ExplosionOnCollision('impact', 1),
               new ExplosionOnDestruction('explosion', 4),
               new DisappearsOutOfRange(),
               new ImpactOnCollision()]);
  }

  double get chance => 0.015;
}

class SubmarineSpawner extends Spawner {

  void processSystem() {
    addEntity([new Transform(pt.x - MAX_WIDTH * 2, (1 + random.nextDouble()*2) * MAX_HEIGHT/8, orientation: 0),
               new Velocity(x: 0.2 + random.nextDouble() * 0.4),
               new Spatial(name: 'submarine.png'),
               new BodyDef('submarine'),
               new Health(4),
               new BodyCount(50),
               new ExplosionOnCollision('impact', 1),
               new ExplosionOnDestruction('explosion', 4),
               new DisappearsOutOfRange(),
               new ImpactOnCollision()]);
  }

  double get chance => 0.01;
}

class JetSpawner extends Spawner {

  void processSystem() {
    addEntity([new Transform(pt.x - MAX_WIDTH * 2, (-2.5 + random.nextDouble()*1) * MAX_HEIGHT/8, orientation: 0),
               new Velocity(x: 0.4 + random.nextDouble() * 0.5),
               new Spatial(name: 'jet.png'),
               new BodyDef('jet'),
               new Health(1),
               new BodyCount(2),
               new ExplosionOnCollision('impact', 1),
               new ExplosionOnDestruction('explosion', 2),
               new DisappearsOutOfRange(),
               new ImpactOnCollision()]);
  }

  double get chance => 0.02;
}

class BattleshipSpawner extends Spawner {

  void processSystem() {
    addEntity([new Transform(pt.x - MAX_WIDTH * 2, -10, orientation: 0),
               new Velocity(x: 0.2 + random.nextDouble() * 0.3),
               new Spatial(name: 'battleship.png'),
               new BodyDef('battleship'),
               new Health(6),
               new BodyCount(100),
               new ExplosionOnCollision('impact', 1),
               new ExplosionOnDestruction('explosion', 5),
               new DisappearsOutOfRange(),
               new ImpactOnCollision()]);
  }

  double get chance => 0.005;
}

class DisappearsOutOfRangeSystem extends EntityProcessingSystem {
  static const MAX_RANGE = MAX_WIDTH * 5;
  Transform pt;
  ComponentMapper<Transform> tm;
  DisappearsOutOfRangeSystem() : super(Aspect.getAspectForAllOf([DisappearsOutOfRange, Transform]));

  void initialize() {
    TagManager tag = world.getManager(new TagManager().runtimeType);
    Entity player = tag.getEntity(TAG_PLAYER);
    tm = new ComponentMapper<Transform>(Transform, world);
    pt = tm.get(player);
  }

  void processEntity(Entity entity) {
    var t = tm.get(entity);
    if ((t.x - pt.x).abs() > MAX_RANGE) {
      entity.deleteFromWorld();
    }
  }
}