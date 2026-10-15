module escape_velocity;

extern fn double sqrt(double value);
extern fn double floor(double value);
extern fn double fma(double first, double second, double third);
const double INVALID_RESULT = -1.0e300;

fn double round_three_even(double value) {
    double scaled = value * 1000.0;
    double lower = floor(scaled);
    double midpoint = lower + 0.5;
    double exact_side = fma(value, 1000.0, -midpoint);
    long rounded = (long)lower;
    if (exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0)) rounded += 1;
    return (double)rounded / 1000.0;
}

fn double escape_velocity(long* values, usz length) @export("escape_velocity") {
    if (values == null || length != 2) return INVALID_RESULT;
    long mass = values[0], radius = values[1];
    if (mass < 0 || mass > 1000000000000000 || radius < 1 || radius > 1000000000) return INVALID_RESULT;
    double velocity = sqrt(2.0 * 6.67430e-11 * (double)mass / (double)radius);
    return round_three_even(velocity);
}
