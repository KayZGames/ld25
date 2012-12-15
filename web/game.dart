library game;

import 'dart:html' hide Entity;

import 'package:dartemis/dartemis.dart';

part 'components.dart';
part 'systems.dart';

void main() {
  CanvasElement gameContainer = query('#gamecontainer');
  window.requestLayoutFrame(() {
    gameContainer.width = MAX_WIDTH;
    gameContainer.height = MAX_HEIGHT;

    Game game = new Game(gameContainer);
    game.start();
  });
}

const String TAG_PLAYER = "player";
const String TAG_CAMERA = "camera";

const int MAX_WIDTH = 800;
const int MAX_HEIGHT = 600;

class Game {
  CanvasElement gameCanvas;
  CanvasRenderingContext2D gameContext;
  World world;
  num lastTime = 0;

  Game(this.gameCanvas) {
    gameContext = gameCanvas.context2d;
  }

  void start() {
    world = new World();

    createWorld(world);

    world.delta = 16;
    world.process();

    gameLoop(16);
  }

  void createWorld(World world) {
    TagManager tm = new TagManager();
    world.addManager(tm);

    Entity e = world.createEntity();
    e.addComponent(new Transform(0, -MAX_HEIGHT/4, orientation: FastMath.HALF_PI));
    e.addComponent(new Velocity());
    e.addComponent(new Spatial());
    e.addComponent(new Mass());
    e.addComponent(new Weapon());
    e.addToWorld();
    tm.register(TAG_PLAYER, e);

    e = world.createEntity();
    e.addComponent(new Transform(0, 0));
    e.addToWorld();
    tm.register(TAG_CAMERA, e);

    e = world.createEntity();
    e.addComponent(new Transform(100, -MAX_HEIGHT/2, orientation: 0));
    e.addComponent(new Velocity(y: 0.01));
    e.addComponent(new Spatial());
    e.addToWorld();

    world.addSystem(new PlayerControlSystem());
    world.addSystem(new GravitationSystem());
    world.addSystem(new MovementSystem());
    world.addSystem(new ExpirationSystem());
    world.addSystem(new WeaponFiringSystem());
    world.addSystem(new CameraSystem());
    world.addSystem(new BackgroundRenderingSystem(gameContext));
    world.addSystem(new SpatialRenderingSystem(gameContext));

    world.initialize();
  }

  void gameLoop(num time) {
    world.delta = time - lastTime;
    lastTime = time;

    world.process();

    requestRedraw();
  }


  void requestRedraw() {
    window.requestAnimationFrame(gameLoop);
  }
}
