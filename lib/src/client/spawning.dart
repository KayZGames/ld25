part of client;

abstract class Spawner extends VoidEntitySystem {
  Transform pt;
  Velocity pv;
  PlayerManager pm;

  void initialize() {
    TagManager tag = world.getManager(new TagManager().runtimeType);
    Entity player = tag.getEntity(TAG_PLAYER);
    var tm = new Mapper<Transform>(Transform, world);
    var vm = new Mapper<Velocity>(Velocity, world);
    pt = tm[player];
    pv = vm[player];
    pm = world.getManager(PlayerManager);
  }

  Entity addEntity(List<Component> components) {
    var entity = world.createEntity();
    components.forEach((component) => entity.addComponent(component));
    entity.addToWorld();
    pm.setPlayer(entity, PLAYER_COMPUTER);
    return entity;
  }

  bool checkProcessing() => random.nextDouble() < chance;

  double get chance;

  double get baseSpeed => max(pv.x / 2, 50.0);

  int get spawnPoint => random.nextBool() ? 1 : -1;
}

class AirplaneSpawner extends Spawner {
  void processSystem() {
    addEntity([
      new Transform(pt.x - MAX_WIDTH * 2 * spawnPoint,
          (-3.5 + random.nextDouble() * 1) * MAX_HEIGHT / 8, orientation: 0),
      new Velocity(x: baseSpeed + random.nextDouble() * 200.0),
      new Spatial(name: 'airplane.png'),
      new BodyDef('airplane'),
      new Health(5),
      new BodyCount(150),
      new ExplosionOnCollision('impact', 1),
      new ExplosionOnDestruction('explosion', 4),
      new DisappearsOutOfRange(),
      new ImpactOnCollision()
    ]);
  }

  double get chance => 0.015;
}

class SubmarineSpawner extends Spawner {
  void processSystem() {
    addEntity([
      new Transform(pt.x - MAX_WIDTH * 2 * spawnPoint,
          (1 + random.nextDouble() * 2) * MAX_HEIGHT / 8, orientation: 0),
      new Velocity(x: baseSpeed + random.nextDouble() * 200.0),
      new Spatial(name: 'submarine.png'),
      new BodyDef('submarine'),
      new Health(4),
      new BodyCount(50),
      new ExplosionOnCollision('impact', 1),
      new ExplosionOnDestruction('explosion', 4),
      new DisappearsOutOfRange(),
      new ImpactOnCollision()
    ]);
  }

  double get chance => 0.01;
}

class JetSpawner extends Spawner {
  void processSystem() {
    addEntity([
      new Transform(pt.x - MAX_WIDTH * 2 * spawnPoint,
          (-2.5 + random.nextDouble() * 1) * MAX_HEIGHT / 8, orientation: 0),
      new Velocity(x: baseSpeed + random.nextDouble() * 250.0),
      new Spatial(name: 'jet.png'),
      new BodyDef('jet'),
      new Health(1),
      new BodyCount(2),
      new ExplosionOnCollision('impact', 1),
      new ExplosionOnDestruction('explosion', 2),
      new DisappearsOutOfRange(),
      new ImpactOnCollision()
    ]);
  }

  double get chance => 0.02;
}

class BattleshipSpawner extends Spawner {
  void processSystem() {
    addEntity([
      new Transform(pt.x - MAX_WIDTH * 2 * spawnPoint, -10, orientation: 0),
      new Velocity(x: pv.x.abs() + 0.05 + random.nextDouble() * 150.0),
      new Spatial(name: 'battleship.png'),
      new BodyDef('battleship'),
      new Health(6),
      new BodyCount(100),
      new ExplosionOnCollision('impact', 1),
      new ExplosionOnDestruction('explosion', 5),
      new DisappearsOutOfRange(),
      new ImpactOnCollision()
    ]);
  }

  double get chance => 0.005;
}

class DisappearsOutOfRangeSystem extends EntityProcessingSystem {
  static const MAX_RANGE = MAX_WIDTH * 5;
  Transform pt;
  Mapper<Transform> tm;
  DisappearsOutOfRangeSystem()
      : super(Aspect.getAspectForAllOf([DisappearsOutOfRange, Transform]));

  void initialize() {
    TagManager tag = world.getManager(new TagManager().runtimeType);
    Entity player = tag.getEntity(TAG_PLAYER);
    tm = new Mapper<Transform>(Transform, world);
    pt = tm[player];
  }

  void processEntity(Entity entity) {
    var t = tm[entity];
    if ((t.x - pt.x).abs() > MAX_RANGE) {
      entity.deleteFromWorld();
    }
  }
}
