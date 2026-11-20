extern fn double floor(double value);

fn double modified_newton_multiple_root(double initial_x, double iteration_count) @export("modified_newton_multiple_root") {
    if (initial_x != initial_x || iteration_count != iteration_count ||
        initial_x < 1.0 || initial_x > 2.0 || iteration_count < 0.0 ||
        iteration_count > 8.0 || floor(iteration_count) != iteration_count) return -1.0;

    usz count = (usz)iteration_count;
    for (usz i = 0; i < count; i++) {
        if (initial_x == 1.0) break;
        double offset = initial_x - 1.0;
        double value = offset * offset * (initial_x + 2.0);
        double derivative = 3.0 * offset * (initial_x + 1.0);
        if (derivative == 0.0 || derivative != derivative) return -1.0;
        initial_x -= 2.0 * (value / derivative);
        if (initial_x != initial_x || initial_x < 1.0 || initial_x > 2.0) return -1.0;
    }
    return initial_x;
}
