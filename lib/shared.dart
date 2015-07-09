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

const String PLAYER_HUMAN = 'human';
const String PLAYER_COMPUTER = 'computer';

const String GROUP_HUMAN_WEAPON = 'human_bullet';
const String GROUP_COMPUTER_WEAPON = 'computer_bullet';

GameState state = new GameState();

class GameState {
  bool started = false;
  bool paused = false;
  int deathToll = 0;
  bool get running => started && !paused;
}