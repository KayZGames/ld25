library game;

import 'dart:html' hide Entity;
import 'dart:math';

import 'package:dartemis/dartemis.dart';
import 'package:ld25/client.dart';

void main() {
  CanvasElement gameContainer = querySelector('#gamecontainer');
  gameContainer.width = MAX_WIDTH;
  gameContainer.height = MAX_HEIGHT;

  Game game = new Game(gameContainer);
  game.start();
}

final Random random = new Random();

class Game {
  CanvasElement gameCanvas;
  CanvasRenderingContext2D gameContext;
  World world;
  num lastTime = 0;

  Game(this.gameCanvas) {
    gameContext = gameCanvas.context2D;
  }

  void start() {
    world = new World();

    createWorld(world);

    requestRedraw();
  }

  void createWorld(World world) {
    TagManager tm = new TagManager();
    world.addManager(tm);

    Entity e;

    e = world.createEntity();
    e.addComponent(new Transform(0, - 3 * MAX_HEIGHT/8, orientation: 0));
    e.addComponent(new Velocity(x: 0.5));
    e.addComponent(new Spatial(name: 'airplane.png'));
    e.addToWorld();

    for (int i =0; i < 10; i++) {
      e = world.createEntity();
      e.addComponent(new Transform(random.nextInt(MAX_WIDTH), MAX_HEIGHT/2, repeatsEveryX: MAX_WIDTH + random.nextInt(MAX_WIDTH)));
      e.addComponent(new Spatial(name: 'plant.png'));
      e.addToWorld();
    }

    for (int i =0; i < 20; i++) {
      e = world.createEntity();
      e.addComponent(new Transform(random.nextInt(MAX_WIDTH), random.nextInt(MAX_HEIGHT), orientation: FastMath.HALF_PI, repeatsEveryX: MAX_WIDTH + random.nextInt(MAX_WIDTH)));
      e.addComponent(new Velocity(y: -0.005 - random.nextDouble() * 0.01));
      e.addComponent(new Spatial(name: 'bubble.png'));
      e.addComponent(new TeleportsOnTarget(0, MAX_HEIGHT));
      e.addToWorld();
    }

    e = world.createEntity();
    e.addComponent(new Transform(0, MAX_HEIGHT/4, orientation: 0));
    e.addComponent(new Velocity());
    e.addComponent(new Spatial(name: "shark.png"));
    e.addComponent(new Mass());
    e.addComponent(new Weapon(cooldownTime: 500));
    e.addToWorld();
    tm.register(e, TAG_PLAYER);

    e = world.createEntity();
    e.addComponent(new Transform(0, 0));
    e.addToWorld();
    tm.register(e, TAG_CAMERA);

    world.addSystem(new PlayerControlSystem());
    world.addSystem(new GravitationSystem());
    world.addSystem(new MovementSystem());
    world.addSystem(new EntityTeleportationSystem());
    world.addSystem(new ExpirationSystem());
    world.addSystem(new WeaponFiringSystem());
    world.addSystem(new CameraSystem());
    world.addSystem(new BackgroundRenderingSystem(gameContext));
    world.addSystem(new SpatialRenderingSystem(gameContext));
    world.addSystem(new ForegroundRenderingSystem(gameContext));

    world.initialize();
  }

  void gameLoop(num time) {
    if (lastTime == 0) {
      world.delta = 16;
    } else {
      world.delta = time - lastTime;
    }
    lastTime = time;

    world.process();

    requestRedraw();
  }


  void requestRedraw() {
    window.requestAnimationFrame(gameLoop);
  }
}

