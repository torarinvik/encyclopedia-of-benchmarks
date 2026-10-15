module pi_approximation;

fn double pi_approximation(double* points, usz point_count) @export("pi_approximation") {
    long inside = 0;
    for (usz index = 0; index < point_count; index++) {
        double x = points[2 * index];
        double y = points[2 * index + 1];
        if (x * x + y * y <= 1.0) { inside += 1; }
    }
    return 4.0 * (double)inside / (double)point_count;
}
