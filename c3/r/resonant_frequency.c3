module resonant_frequency;

extern fn double sqrt(double value);
const double PI = 3.14159265358979323846;
const double INVALID_RESULT = -1.0e300;

fn double resonant_frequency(long* values, usz length) @export("resonant_frequency") {
    if (values == null || length != 2) return INVALID_RESULT;
    long inductance = values[0];
    long capacitance = values[1];
    if (inductance < 1 || inductance > 1000 || capacitance < 1 || capacitance > 1000) return INVALID_RESULT;
    return 1.0 / (2.0 * PI * sqrt((double)inductance * (double)capacitance));
}
