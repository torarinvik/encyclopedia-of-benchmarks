module distance_formula;

extern fn double sqrt(double value);
const double INVALID_RESULT = -1.0e300;

fn double distance_formula(long* values, usz length) @export("distance_formula") {
    if (values == null || length != 4) return INVALID_RESULT;
    for (usz i = 0; i < 4; i++) {
        if (values[i] < -1000000 || values[i] > 1000000) return INVALID_RESULT;
    }
    double dx = (double)(values[2] - values[0]);
    double dy = (double)(values[3] - values[0]);
    return sqrt(dx * dx + dy * dy);
}
