import 'dart:html' hide Entity;

import 'package:dartemis/dartemis.dart';


void main() {
  CanvasElement gameContainer = query('#gamecontainer');

  Game game = new Game(gameContainer);
  game.start();
}

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


//    world.addSystem(...);

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
