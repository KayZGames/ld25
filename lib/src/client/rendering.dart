part of client;

class DebugBodyDefRenderingSystem extends EntityProcessingSystem {
  ComponentMapper<Transform> tm;
  ComponentMapper<BodyDef> bm;
  CanvasRenderingContext2D context;
  Map<String, List<Polygon>> bodyDefs;

  DebugBodyDefRenderingSystem(this.context, this.bodyDefs) : super(Aspect.getAspectForAllOf([Transform, BodyDef]));

  void initialize() {
    tm = new ComponentMapper<Transform>(Transform, world);
    bm = new ComponentMapper<BodyDef>(BodyDef, world);
  }

  void processEntity(Entity entity) {
    var t = tm.get(entity);
    var b = bm.get(entity);

    var pos = t.position;

    context.beginPath();
    bodyDefs[b.bodyId].forEach((Polygon polygon) {
      var rotated = rotate(pos, polygon.vertices.last, t.rotation);
      context.moveTo(rotated.x, rotated.y);
      polygon.vertices.forEach((vertex) {
        var rotated = rotate(pos, vertex, t.rotation);
        context.lineTo(rotated.x, rotated.y);
      });
    });
    context.stroke();
  }

}

class BufferToCanvasSystem extends VoidEntitySystem {
  CanvasElement buffer;
  CanvasRenderingContext2D ctx;

  BufferToCanvasSystem(this.buffer, this.ctx);

  void processSystem() {
    ctx.drawImage(buffer, 0, 0);
  }
}

class MenuSystem extends VoidEntitySystem {
  CanvasElement canvas;
  CanvasRenderingContext2D ctx;
  CanvasQuery startMenu, pauseMenu;
  MenuSystem(CanvasElement canvas) : canvas = canvas,
                                                 ctx = canvas.context2D;

  void initialize() {
    startMenu = _createMenu('Start');
    pauseMenu = _createMenu('Resume');
    var button = _getButton();
    cq(canvas).framework.onMouseDown.listen((event) {
      if (button.containsPoint(event.position)) {
        state.started = true;
        state.paused = false;
      }
    });
  }

  CanvasQuery _createMenu(String buttonText) {
    var menu = cq(MAX_WIDTH, MAX_HEIGHT);
    menu..textBaseline = 'top'
        ..font = '12px Verdana';
    var bounds = menu.textBoundaries(buttonText);
    var button = _getButton();
    menu..roundRect(20, 20, MAX_WIDTH - 40, MAX_HEIGHT - 40, 20, strokeStyle: 'black', fillStyle: 'blue')
        ..roundRect(button.left, button.top, button.width, button.height, 10, strokeStyle: 'red', fillStyle: 'green')
        ..fillText(buttonText, MAX_WIDTH ~/ 2 - bounds.width ~/ 2, MAX_HEIGHT ~/2 - bounds.height ~/ 2);
    return menu;
  }

  Rectangle _getButton() {
    var buttonLeft = MAX_WIDTH ~/ 2 - 50;
    var buttonTop = MAX_HEIGHT ~/2 - 15;
    var buttonWidth = 100;
    var buttonHeight = 30;
    return new Rectangle(buttonLeft, buttonTop, buttonWidth, buttonHeight);
  }

  void processSystem() {
    if (state.paused) {
      ctx.drawImage(pauseMenu.canvas, 0, 0);
    } else {
      ctx.drawImage(startMenu.canvas, 0, 0);
    }
  }

  bool checkProcessing() => super.checkProcessing() && !state.running;
}



class BackgroundRenderingSystem extends VoidEntitySystem {
  Transform cameraTransform;

  CanvasRenderingContext2D context;

  BackgroundRenderingSystem(this.context);

  void initialize() {
    ComponentMapper<Transform> transformMapper = new ComponentMapper<Transform>(Transform.type, world);
    TagManager tagManager = world.getManager(TagManager);

    Entity camera = tagManager.getEntity(TAG_CAMERA);

    cameraTransform = transformMapper.get(camera);
  }

  void processSystem() {
    context..setTransform(1, 0, 0, 1, 0, 0)
           ..translate(-cameraTransform.x, MAX_HEIGHT/2)
           ..fillStyle = waterColor
           ..fillRect(cameraTransform.x, 0, MAX_WIDTH, MAX_HEIGHT/2)
           ..fillStyle = "lightblue"
           ..fillRect(cameraTransform.x, -MAX_HEIGHT/2, MAX_WIDTH, MAX_HEIGHT/2);
  }

  String get waterColor {
    if (state.deathToll == 200) {
      return 'darkred';
    } else {
      return 'blue';
    }
  }
}

class ForegroundRenderingSystem extends BackgroundRenderingSystem {
  ForegroundRenderingSystem(context) : super(context);

  void processSystem() {
    context.save();
    try {
      context..globalAlpha = 0.25
             ..fillStyle = waterColor
             ..fillRect(cameraTransform.x, 0, MAX_WIDTH, MAX_HEIGHT/2);;
    } finally {
      context.restore();
    }
  }
}

class SpatialRenderingSystem extends EntityProcessingSystem {
  CanvasRenderingContext2D context;
  SpriteSheet spriteSheet;

  ComponentMapper<Transform> transformMapper;
  ComponentMapper<Spatial> spatialMapper;

  Transform cameraTransform;

  SpatialRenderingSystem(this.context, this.spriteSheet) : super(Aspect.getAspectForAllOf([Spatial, Transform]));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(Transform, world);
    spatialMapper = new ComponentMapper<Spatial>(Spatial, world);

    TagManager tagManager = world.getManager(TagManager);
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    cameraTransform = transformMapper.get(camera);
  }

  void processEntity(Entity e) {
    Transform t = transformMapper.get(e);
    Spatial s = spatialMapper.get(e);

    num x = t.x;
    num y = t.y;
    double orientation = t.orientation;

    if (t.repeatsEveryX == 0) {
      drawSpatial(s, x, y, orientation);
    } else {
      int minFactor = (cameraTransform.x ~/ t.repeatsEveryX).toInt() - 1;
      int maxFactor = ((cameraTransform.x+MAX_WIDTH) ~/ t.repeatsEveryX).toInt() + 1;
      for (int i = minFactor; i < maxFactor; i++) {
        num offsetX = i * t.repeatsEveryX + x;
        drawSpatial(s, offsetX, y, orientation);
      }
    }
  }

  void drawSpatial(Spatial s, num x, num y, double orientation) {
    if (null == s.name) {
      context..fillStyle = "grey"
          ..fillRect(x, y, 5, 5);
    } else {
      context.save();
      try {
        context.translate(x, y);
        context.rotate(orientation);
        var sprite = spriteSheet[s.name];
        context.drawImageToRect(spriteSheet.image, sprite.dst, sourceRect: sprite.src);
      } finally {
        context.restore();
      }
    }
  }
}