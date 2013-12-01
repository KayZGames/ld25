library game;

import 'dart:math';

import 'package:dartemis/dartemis.dart';
import 'package:ld25/client.dart';

void main() => new Game().start();

final Random random = new Random();

class Game extends GameBase {
  CanvasElement buffer;
  CanvasRenderingContext2D bufferCtx;

  Game() : super('ld25', '#gamecontainer', MAX_WIDTH, MAX_HEIGHT);

  void createEntities() {
    TagManager tm = world.getManager(TagManager);

    addEntity([new Transform(0, - 3 * MAX_HEIGHT/8, orientation: 0),
               new Velocity(x: 0.5),
               new Spatial(name: 'airplane.png'),
               new BodyDef('airplane'),
               new DestroyOnCollision()]);


    for (int i =0; i < 10; i++) {
      addEntity([new Transform(random.nextInt(MAX_WIDTH), MAX_HEIGHT/2, repeatsEveryX: MAX_WIDTH + random.nextInt(MAX_WIDTH)),
                 new Spatial(name: 'plant.png')]);
    }

    for (int i =0; i < 20; i++) {
      addEntity([new Transform(random.nextInt(MAX_WIDTH), random.nextInt(MAX_HEIGHT), orientation: FastMath.HALF_PI, repeatsEveryX: MAX_WIDTH + random.nextInt(MAX_WIDTH)),
                 new Velocity(y: -0.005 - random.nextDouble() * 0.01),
                 new Spatial(name: 'bubble.png'),
                 new TeleportsOnTarget(0, MAX_HEIGHT)]);
    }

    Entity e = addEntity([new Transform(0, MAX_HEIGHT/4, orientation: 0),
                          new Velocity(),
                          new Spatial(name: "shark.png"),
                          new Mass(),
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
            new CameraSystem(),
            new BackgroundRenderingSystem(bufferCtx),
            new SpatialRenderingSystem(bufferCtx, spriteSheet),
            new ForegroundRenderingSystem(bufferCtx),
            new BufferToCanvasSystem(buffer, ctx),
            new SoundSystem(helper.audioHelper),
            new CollisionDetectionSystem(bodyDefs),
            new DestroyOnCollisionSystem(),
            new MenuSystem(canvas)
      ];
  }

  void onInit() {
    world.addManager(new TagManager());
    buffer = new CanvasElement(width: MAX_WIDTH, height: MAX_HEIGHT);
    bufferCtx = buffer.context2D;

    helper.audioHelper.loadAudioClips(['laser_shoot']);
  }

  void onInitDone() {}
}
