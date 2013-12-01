library shared;

import 'dart:math';

import 'package:vector_math/vector_math.dart';
import 'package:dartemis/dartemis.dart';
export 'package:dartemis/dartemis.dart';

part 'src/shared/components.dart';

const String TAG_PLAYER = "player";
const String TAG_CAMERA = "camera";

const int MAX_WIDTH = 800;
const int MAX_HEIGHT = 600;

GameState state = new GameState();

class GameState {
  bool started = false;
  bool paused = false;
  bool get running => started && !paused;
}