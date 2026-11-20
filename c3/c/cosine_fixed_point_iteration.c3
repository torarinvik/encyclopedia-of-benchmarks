extern fn double cos(double value);
extern fn double floor(double value);

fn double cosine_fixed_point_iteration(double initial, double source_n) @export("cosine_fixed_point_iteration") {
    if (initial != initial || source_n != source_n || initial < 0.0 || initial > 2.0 ||
        source_n < 0.0 || source_n > 64.0 || floor(source_n) != source_n) return -1.0;

    usz updates = (usz)source_n + 1;
    for (usz iteration = 0; iteration < updates; iteration++) {
        initial = 0.5 * (cos(initial) + 2.0);
    }
    return initial;
}
