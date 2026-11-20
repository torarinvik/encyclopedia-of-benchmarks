module liu_hui_pi_approximation;

extern fn double sqrt(double value);

fn long liu_hui_pi_approximation(long* values, usz length) @export("liu_hui_pi_approximation") {
    if (values == null || length != 1) return -1;
    long doublings = values[0];
    if (doublings < 0 || doublings > 16) return -1;

    long sides = 6;
    double side = 1.0;
    double apothem = sqrt(0.75);
    for (long i = 0; i < doublings; i += 1) {
        double half_side = side / 2.0;
        double height = 1.0 - apothem;
        side = sqrt(half_side * half_side + height * height);
        sides *= 2;
        double next_half_side = side / 2.0;
        apothem = sqrt(1.0 - next_half_side * next_half_side);
    }

    double area = (double)sides * side * apothem / 2.0;
    return (long)(area * 1000000.0 + 0.5);
}
