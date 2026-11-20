module infinite_knight_distance;

const long MAX_COORDINATE = 1000000000;

fn long infinite_knight_distance(long* input, usz length) @export("infinite_knight_distance") {
    if (input == null || length != 2) return -1;
    long dx = input[0], dy = input[1];
    if (dx < -MAX_COORDINATE || dx > MAX_COORDINATE ||
        dy < -MAX_COORDINATE || dy > MAX_COORDINATE) return -1;
    long abs_x = dx < 0 ? -dx : dx;
    long abs_y = dy < 0 ? -dy : dy;
    long large = abs_x > abs_y ? abs_x : abs_y;
    long small = abs_x < abs_y ? abs_x : abs_y;
    if (large == 1 && small == 0) return 3;
    if (large == 2 && small == 2) return 4;
    long distance = (large + 1) / 2;
    long diagonal_bound = (large + small + 2) / 3;
    if (diagonal_bound > distance) distance = diagonal_bound;
    if ((large + small - distance) % 2 != 0) distance++;
    return distance;
}
