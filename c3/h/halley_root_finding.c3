extern fn double floor(double value);

fn double halley_root_finding(double initial_x, double iteration_count) @export("halley_root_finding") {
    if (initial_x != initial_x || iteration_count != iteration_count ||
        initial_x < 0.5 || initial_x > 2.0 || iteration_count < 0.0 ||
        iteration_count > 8.0 || floor(iteration_count) != iteration_count) return -1.0;

    usz count = (usz)iteration_count;
    for (usz i = 0; i < count; i++) {
        double value = initial_x * initial_x * initial_x - 2.0;
        double first = 3.0 * initial_x * initial_x;
        double second = 6.0 * initial_x;
        double denominator = 2.0 * first * first - value * second;
        if (denominator == 0.0 || denominator != denominator) return -1.0;
        initial_x -= (2.0 * value * first) / denominator;
        if (initial_x != initial_x || initial_x < 0.5 || initial_x > 2.0) return -1.0;
    }
    return initial_x;
}
