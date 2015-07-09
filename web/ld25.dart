library game;

import 'package:dartemis/dartemis.dart';
import 'package:ld25/client.dart';

void main() => new Game().start();

class Game extends GameBase {
  CanvasElement buffer;
  CanvasRenderingContext2D bufferCtx;

  Game() : super('ld25', '#gamecontainer', MAX_WIDTH, MAX_HEIGHT);

  void createEntities() {
    TagManager tm = world.getManager(TagManager);
    PlayerManager pm = world.getManager(PlayerManager);

    for (int i = 0; i < 10; i++) {
      addEntity([
        new Transform(random.nextInt(MAX_WIDTH), MAX_HEIGHT / 2,
            repeatsEveryX: MAX_WIDTH + random.nextInt(MAX_WIDTH)),
        new Spatial(name: 'plant.png')
      ]);
    }

    for (int i = 0; i < 20; i++) {
      addEntity([
        new Transform(random.nextInt(MAX_WIDTH), random.nextInt(MAX_HEIGHT),
            orientation: PI / 2,
            repeatsEveryX: MAX_WIDTH + random.nextInt(MAX_WIDTH)),
        new Velocity(y: -5.0 - random.nextDouble() * 10.0),
        new Spatial(name: 'bubble.png'),
        new TeleportsOnTarget(0, MAX_HEIGHT, sound: 'bubble_burst')
      ]);
    }

    Entity e = addEntity([
      new Transform(0, MAX_HEIGHT / 4, orientation: 0),
      new Velocity(),
      new Spatial(name: "shark.png"),
      new Mass(),
      new BodyDef('shark'),
      new Weapon(cooldownTime: 0.5),
      new Controller()
    ]);
    tm.register(e, TAG_PLAYER);
    pm.setPlayer(e, PLAYER_HUMAN);

    e = addEntity([new Transform(0, 0)]);
    tm.register(e, TAG_CAMERA);
  }

  Map<int, List<EntitySystem>> getSystems() {
    return {
      GameBase.rendering: [
        new BackgroundRenderingSystem(bufferCtx),
        new SpatialRenderingSystem(bufferCtx, spriteSheet),
        new ForegroundRenderingSystem(bufferCtx),
//            new DebugBodyDefRenderingSystem(bufferCtx, bodyDefs),
        new BufferToCanvasSystem(buffer, ctx),
        new HudRenderingSystem(ctx),
        new MenuSystem(canvas),
      ],
      GameBase.physics: [
        new PlayerControlSystem(),
        new AirplaneSpawner(),
        new SubmarineSpawner(),
        new JetSpawner(),
        new BattleshipSpawner(),
        new GravitationSystem(),
        new MovementSystem(),
        new EntityTeleportationSystem(),
        new ExpirationSystem(),
        new WeaponFiringSystem(),
        new ComputerCollisionDetectionSystem(bodyDefs),
        new HumanCollisionDetectionSystem(bodyDefs),
        new DestroyOnCollisionSystem(),
        new DamageToHealthSystem(),
        new ExplosionOnCollisionSystem(),
        new ExplosionOnDestructionSystem(bodyDefs),
        new DestructionSystem(),
        new DeathTollSystem(),
        new CameraSystem(),
        new SoundSystem(helper.audioHelper),
        new CollisionCleanupSystem(),
        new DisappearsOutOfRangeSystem()
      ]
    };
  }

  onInit() {
    world.addManager(new TagManager());
    world.addManager(new PlayerManager());
    world.addManager(new GroupManager());
    buffer = new CanvasElement(width: MAX_WIDTH, height: MAX_HEIGHT);
    bufferCtx = buffer.context2D;

    helper.audioHelper.loadAudioClips(
        ['laser_shoot', 'bubble_burst', 'bullet_hit', 'explosion']);
  }

}
