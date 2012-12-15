library game;

import 'dart:html' hide Entity;
import 'dart:math';

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

final Random random = new Random();

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
    e.addComponent(new Transform(0, MAX_HEIGHT/4, orientation: 0));
    e.addComponent(new Velocity());
    e.addComponent(new Spatial(name: "shark.png"));
    e.addComponent(new Mass());
    e.addComponent(new Weapon());
    e.addToWorld();
    tm.register(TAG_PLAYER, e);

    e = world.createEntity();
    e.addComponent(new Transform(0, 0));
    e.addToWorld();
    tm.register(TAG_CAMERA, e);

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

    world.addSystem(new PlayerControlSystem());
    world.addSystem(new GravitationSystem());
    world.addSystem(new MovementSystem());
    world.addSystem(new EntityTeleportationSystem());
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

void loadImages() {
  List<String> images = ['shark.png', 'laser.png', 'bubble.png', 'plant.png'];
  images.forEach((image) => ImageCache.withImage(image, (element) {}));
}

class ImageCache {
  static final Map<String, ImageElement> loadedImages = new Map<String, ImageElement>();

  static void withImage(String imageName, void action(ImageElement image)) {
    ImageElement image = loadedImages[imageName];
    if (null == image) {
      image = new ImageElement();
      image.on.load.add((event) {
        action(image);
        loadedImages[imageName] = image;
      });
      image.src = "res/img/${imageName}";
    } else {
      action(image);
    }
  }
}