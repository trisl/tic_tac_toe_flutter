/// The two marks that can occupy a cell. The human plays [x], the robot [o].
enum Mark {
  x,
  o;

  Mark get opponent => this == Mark.x ? Mark.o : Mark.x;
}
