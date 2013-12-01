library game;

import 'dart:math';

import 'package:dartemis/dartemis.dart';
import 'package:ld25/client.dart';

void main() => new Game().start();

class Game extends GameBase {
  CanvasElement buffer;
  CanvasRenderingContext2D bufferCtx;

  Game() : super('ld25', '#gamecontainer', MAX_WIDTH, MAX_HEIGHT);

  void createEntities() {
    TagManager tm = world.getManager(TagManager);

    addEntity([new Transform(0, - 3 * MAX_HEIGHT/8, orientation: 0),
               new Velocity(x: 0.3 + random.nextDouble() * 0.4),
               new Spatial(name: 'airplane.png'),
               new BodyDef('airplane'),
               new Health(10),
               new BodyCount(150),
               new ExplosionOnCollision('impact', 1),
               new ExplosionOnDestruction('explosion', 4),
               new ImpactOnCollision()]);

    addEntity([new Transform(0, - 2 * MAX_HEIGHT/8, orientation: 0),
               new Velocity(x: 0.4 + random.nextDouble() * 0.5),
               new Spatial(name: 'jet.png'),
               new BodyDef('jet'),
               new Health(2),
               new BodyCount(2),
               new ExplosionOnCollision('impact', 1),
               new ExplosionOnDestruction('explosion', 2),
               new ImpactOnCollision()]);

    addEntity([new Transform(0, -10, orientation: 0),
               new Velocity(x: 0.2 + random.nextDouble() * 0.3),
               new Spatial(name: 'battleship.png'),
               new BodyDef('battleship'),
               new Health(12),
               new BodyCount(100),
               new ExplosionOnCollision('impact', 1),
               new ExplosionOnDestruction('explosion', 5),
               new ImpactOnCollision()]);

    addEntity([new Transform(0, 2 * MAX_HEIGHT/8, orientation: 0),
               new Velocity(x: 0.2 + random.nextDouble() * 0.4),
               new Spatial(name: 'submarine.png'),
               new BodyDef('submarine'),
               new Health(8),
               new BodyCount(50),
               new ExplosionOnCollision('impact', 1),
               new ExplosionOnDestruction('explosion', 4),
               new ImpactOnCollision()]);


    for (int i =0; i < 10; i++) {
      addEntity([new Transform(random.nextInt(MAX_WIDTH), MAX_HEIGHT/2, repeatsEveryX: MAX_WIDTH + random.nextInt(MAX_WIDTH)),
                 new Spatial(name: 'plant.png')]);
    }

    for (int i =0; i < 20; i++) {
      addEntity([new Transform(random.nextInt(MAX_WIDTH), random.nextInt(MAX_HEIGHT), orientation: FastMath.HALF_PI, repeatsEveryX: MAX_WIDTH + random.nextInt(MAX_WIDTH)),
                 new Velocity(y: -0.005 - random.nextDouble() * 0.01),
                 new Spatial(name: 'bubble.png'),
                 new TeleportsOnTarget(0, MAX_HEIGHT, sound: 'bubble_burst')]);
    }

    Entity e = addEntity([new Transform(0, MAX_HEIGHT/4, orientation: 0),
                          new Velocity(),
                          new Spatial(name: "shark.png"),
                          new Mass(),
                          new BodyDef('shark'),
                          new Weapon(cooldownTime: 500)]);
    tm.register(e, TAG_PLAYER);

    e = addEntity([new Transform(0, 0)]);
    tm.register(e, TAG_CAMERA);
  }

  List<EntitySystem> getSystems() {
    return [
            new PlayerControlSystem(),
            new GravitationSystem(),
            new MovementSystem(),
            new EntityTeleportationSystem(),
            new ExpirationSystem(),
            new WeaponFiringSystem(),
            new CollisionDetectionSystem(bodyDefs),
            new DestroyOnCollisionSystem(),
            new DamageToHealthSystem(),
            new ExplosionOnCollisionSystem(),
            new ExplosionOnDestructionSystem(bodyDefs),
            new DestructionSystem(),
            new DeathTollSystem(),
            new CameraSystem(),
            new BackgroundRenderingSystem(bufferCtx),
            new SpatialRenderingSystem(bufferCtx, spriteSheet),
            new ForegroundRenderingSystem(bufferCtx),
            new DebugBodyDefRenderingSystem(bufferCtx, bodyDefs),
            new BufferToCanvasSystem(buffer, ctx),
            new HudRenderingSystem(ctx),
            new SoundSystem(helper.audioHelper),
            new MenuSystem(canvas),
            new CollisionCleanupSystem()
      ];
  }

  void onInit() {
    world.addManager(new TagManager());
    buffer = new CanvasElement(width: MAX_WIDTH, height: MAX_HEIGHT);
    bufferCtx = buffer.context2D;

    helper.audioHelper.loadAudioClips(['laser_shoot', 'bubble_burst']);
  }

  void onInitDone() {}
}
