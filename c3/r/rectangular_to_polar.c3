module rectangular_to_polar;

extern fn double sqrt(double value);
extern fn double atan2(double y, double x);
extern fn double round(double value);

const double INVALID_RESULT = -1.0e300;
const double DEGREE_FACTOR = 57.2957795130823208768;

fn double round_two(double value) {
    if (value == 0.0) return value;
    return round(value * 100.0) / 100.0;
}

fn double rectangular_to_polar(double real, double imag, double component) @export("rectangular_to_polar") {
    if (real != real || imag != imag || component != component ||
        real < -1000000.0 || real > 1000000.0 || imag < -1000000.0 || imag > 1000000.0 ||
        (component != 0.0 && component != 1.0)) return INVALID_RESULT;
    if (component == 0.0) return round_two(sqrt(real * real + imag * imag));
    return round_two(atan2(imag, real) * DEGREE_FACTOR);
}
