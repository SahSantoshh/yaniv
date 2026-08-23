class Player {
  String name;
  List<int> scores = [];
  List<int> totals = [];
  int joinedAtRound;
  
  Player(this.name, {this.joinedAtRound = 0});
}
