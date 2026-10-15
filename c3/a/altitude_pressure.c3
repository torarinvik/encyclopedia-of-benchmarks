module altitude_pressure;

extern fn double pow(double base, double exponent);

// Estimate altitude from pressure using the pinned source formula.
fn double altitude_pressure(double pressure) @export("altitude_pressure") {
    if (pressure < 0.0 || pressure > 101325.0) return -1.0;
    if (pressure == 0.0) return 44330.0;
    double exponent = 1.0 / 5.5255;
    return 44330.0 * (1.0 - pow(pressure / 101325.0, exponent));
}
