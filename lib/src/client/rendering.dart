part of client;

class HudRenderingSystem extends VoidEntitySystem {
  CanvasRenderingContext2D ctx;
  HudRenderingSystem(this.ctx);

  void processSystem() {
    ctx
      ..fillStyle = 'darkred'
      ..fillText('Death Toll: ${state.deathToll}', 0, 0);
  }
}

class DebugBodyDefRenderingSystem extends EntityProcessingSystem {
  Mapper<Transform> tm;
  Mapper<BodyDef> bm;
  CanvasRenderingContext2D context;
  Map<String, List<Polygon>> bodyDefs;

  DebugBodyDefRenderingSystem(this.context, this.bodyDefs)
      : super(Aspect.getAspectForAllOf([Transform, BodyDef]));

  void initialize() {
    tm = new Mapper<Transform>(Transform, world);
    bm = new Mapper<BodyDef>(BodyDef, world);
  }

  void processEntity(Entity entity) {
    var t = tm[entity];
    var b = bm[entity];

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
  CanvasElement startMenu, pauseMenu;
  MenuSystem(CanvasElement canvas)
      : canvas = canvas,
        ctx = canvas.context2D;

  void initialize() {
    startMenu = _createMenu('Start');
    pauseMenu = _createMenu('Resume');
    var button = _getButton();
    canvas.onMouseDown.listen((event) {
      if (button.containsPoint(event.offset)) {
        state.started = true;
        state.paused = false;
      }
    });
  }

  CanvasElement _createMenu(String buttonText) {
    var menu = new CanvasElement(width: MAX_WIDTH, height: MAX_HEIGHT);
    menu.context2D
      ..textBaseline = 'top'
      ..font = '12px Verdana';
    var bounds = menu.context2D.measureText(buttonText);
    var button = _getButton();
    menu.context2D
      ..fillStyle = 'blue'
      ..strokeStyle = 'black'
      ..strokeRect(20, 20, MAX_WIDTH - 40, MAX_HEIGHT - 40)
      ..fillRect(20, 20, MAX_WIDTH - 40, MAX_HEIGHT - 40)
      ..fillStyle = 'green'
      ..strokeStyle = 'red'
      ..strokeRect(button.left, button.top, button.width, button.height)
      ..fillRect(button.left, button.top, button.width, button.height)
      ..fillStyle = 'black'
      ..fillText(buttonText, MAX_WIDTH ~/ 2 - bounds.width ~/ 2,
          MAX_HEIGHT ~/ 2 - (12 * 1.6) ~/ 2);
    return menu;
  }

  Rectangle _getButton() {
    var buttonLeft = MAX_WIDTH ~/ 2 - 50;
    var buttonTop = MAX_HEIGHT ~/ 2 - 15;
    var buttonWidth = 100;
    var buttonHeight = 30;
    return new Rectangle(buttonLeft, buttonTop, buttonWidth, buttonHeight);
  }

  void processSystem() {
    if (state.paused) {
      ctx.drawImage(pauseMenu, 0, 0);
    } else {
      ctx.drawImage(startMenu, 0, 0);
    }
  }

  bool checkProcessing() => super.checkProcessing() && !state.running;
}

class BackgroundRenderingSystem extends VoidEntitySystem {
  Transform cameraTransform;

  CanvasRenderingContext2D context;

  BackgroundRenderingSystem(this.context);

  void initialize() {
    Mapper<Transform> transformMapper =
        new Mapper<Transform>(Transform.type, world);
    TagManager tagManager = world.getManager(TagManager);

    Entity camera = tagManager.getEntity(TAG_CAMERA);

    cameraTransform = transformMapper[camera];
  }

  void processSystem() {
    context
      ..setTransform(1, 0, 0, 1, 0, 0)
      ..translate(-cameraTransform.x, MAX_HEIGHT / 2)
      ..fillStyle = waterColor
      ..fillRect(cameraTransform.x, 0, MAX_WIDTH, MAX_HEIGHT / 2)
      ..fillStyle = skyColor
      ..fillRect(cameraTransform.x, -MAX_HEIGHT / 2, MAX_WIDTH, MAX_HEIGHT / 2);
  }

  String get waterColor {
    int v = min(127, state.deathToll ~/ 100);
    return rgbToHex(v, 0, 255 - v * 2);
  }

  String get skyColor {
    int v = min(64, state.deathToll ~/ 100);
    print(v);
    return rgbToHex(v, 255 - 2 * v, 255 - 4 * v ~/ 3);
  }

  String rgbToHex(int red, int green, int blue) =>
      '#${red.toRadixString(16).padLeft(2, '0')}${green.toRadixString(16).padLeft(2, '0')}${blue.toRadixString(16).padLeft(2, '0')}';
}

class ForegroundRenderingSystem extends BackgroundRenderingSystem {
  ForegroundRenderingSystem(context) : super(context);

  void processSystem() {
    context.save();
    try {
      context
        ..globalAlpha = 0.25
        ..fillStyle = waterColor
        ..fillRect(cameraTransform.x, 0, MAX_WIDTH, MAX_HEIGHT / 2);
      ;
    } finally {
      context.restore();
    }
  }
}

class SpatialRenderingSystem extends EntityProcessingSystem {
  CanvasRenderingContext2D context;
  SpriteSheet spriteSheet;

  Mapper<Transform> transformMapper;
  Mapper<Spatial> spatialMapper;

  Transform cameraTransform;

  SpatialRenderingSystem(this.context, this.spriteSheet)
      : super(Aspect.getAspectForAllOf([Spatial, Transform]));

  void initialize() {
    transformMapper = new Mapper<Transform>(Transform, world);
    spatialMapper = new Mapper<Spatial>(Spatial, world);

    TagManager tagManager = world.getManager(TagManager);
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    cameraTransform = transformMapper[camera];
  }

  void processEntity(Entity e) {
    Transform t = transformMapper[e];
    Spatial s = spatialMapper[e];

    num x = t.x;
    num y = t.y;
    double orientation = t.orientation;

    if (t.repeatsEveryX == 0) {
      drawSpatial(s, x, y, orientation);
    } else {
      int minFactor = (cameraTransform.x ~/ t.repeatsEveryX).toInt() - 1;
      int maxFactor =
          ((cameraTransform.x + MAX_WIDTH) ~/ t.repeatsEveryX).toInt() + 1;
      for (int i = minFactor; i < maxFactor; i++) {
        num offsetX = i * t.repeatsEveryX + x;
        drawSpatial(s, offsetX, y, orientation);
      }
    }
  }

  void drawSpatial(Spatial s, num x, num y, double orientation) {
    if (null == s.name) {
      context
        ..fillStyle = "grey"
        ..fillRect(x, y, 5, 5);
    } else {
      context.save();
      try {
        context.translate(x, y);
        context.rotate(orientation);
        var sprite = spriteSheet[s.name];
        context.drawImageToRect(spriteSheet.image, sprite.dst,
            sourceRect: sprite.src);
      } finally {
        context.restore();
      }
    }
  }
}
