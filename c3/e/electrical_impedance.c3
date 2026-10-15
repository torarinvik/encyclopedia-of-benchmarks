module electrical_impedance;

extern fn double sqrt(double value);
const double INVALID_RESULT = -1.0e300;

fn double electrical_impedance(long* values, usz length) @export("electrical_impedance") {
    if (values == null || length != 3) return INVALID_RESULT;
    long resistance = values[0];
    long reactance = values[1];
    long impedance = values[2];
    if (resistance < 0 || resistance > 1000 || reactance < 0 || reactance > 1000 || impedance < 0 || impedance > 1000) return INVALID_RESULT;
    int zeros = 0;
    if (resistance == 0) zeros++;
    if (reactance == 0) zeros++;
    if (impedance == 0) zeros++;
    if (zeros != 1) return INVALID_RESULT;
    double r = (double)resistance;
    double x = (double)reactance;
    double z = (double)impedance;
    double radicand;
    if (resistance == 0) {
        radicand = z * z - x * x;
    } else if (reactance == 0) {
        radicand = z * z - r * r;
    } else {
        radicand = r * r + x * x;
    }
    return radicand < 0.0 ? INVALID_RESULT : sqrt(radicand);
}
