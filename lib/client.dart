library client;

import 'dart:math';
import 'dart:html';
export 'dart:html';

import 'package:ld25/shared.dart';
export 'package:ld25/shared.dart';
import 'package:gamedev_helpers/gamedev_helpers.dart';
export 'package:gamedev_helpers/gamedev_helpers.dart';
import 'package:vector_math/vector_math.dart';

part 'src/client/collision_handling.dart';
part 'src/client/input.dart';
part 'src/client/rendering.dart';
part 'src/client/spawning.dart';
part 'src/client/systems.dart';


Vector2 rotate(Vector2 o, Vector2 p, Matrix2 mRot) {
  return o + mRot.transform(p.clone());
}