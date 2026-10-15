module binary_step;

const double INVALID_RESULT = -1.0e300;

fn double binary_step(double x) @export("binary_step") {
    if (x != x || x < -1000000.0 || x > 1000000.0) return INVALID_RESULT;
    return x >= 0.0 ? 1.0 : 0.0;
}
