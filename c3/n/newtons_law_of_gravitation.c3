module newtons_law_of_gravitation;

extern fn double sqrt(double value);
const double INVALID_RESULT = -1.0e300;
const double GRAVITATIONAL_CONSTANT = 6.6743e-11;

fn double newtons_law_of_gravitation(long* values, usz length) @export("newtons_law_of_gravitation") {
    if (values == null || length != 4) return INVALID_RESULT;
    long target = values[0], a = values[1], b = values[2], c = values[3];
    if (target < 0 || target > 3 || a < 1 || a > 1000 || b < 1 || b > 1000 || c < 1 || c > 1000) return INVALID_RESULT;
    if (target == 0) return GRAVITATIONAL_CONSTANT * ((double)a * (double)b) / ((double)c * (double)c);
    if (target == 1) return (double)a * ((double)c * (double)c) / (GRAVITATIONAL_CONSTANT * (double)b);
    if (target == 2) return (double)a * ((double)c * (double)c) / (GRAVITATIONAL_CONSTANT * (double)b);
    return sqrt((GRAVITATIONAL_CONSTANT * ((double)b * (double)c)) / (double)a);
}
