part of game;

class Transform extends Component {
  static Type get type => new Transform._hack().runtimeType;
  Transform._hack();
  num x, y;
  num orientation;
  Transform(this.x, this.y, {this.orientation : 0});
}

class Velocity extends Component {
  static Type get type => new Velocity._hack().runtimeType;
  Velocity._hack();
  num x, y;
  num max;
  Velocity({this.x : 0, this.y: 0, this.max: 1});
}

class Spatial extends Component {
  static Type get type => new Spatial._hack().runtimeType;
  Spatial._hack();
  Spatial();
}

class Mass extends Component {
  static Type get type => new Mass._hack().runtimeType;
  Mass._hack();
  Mass();
}