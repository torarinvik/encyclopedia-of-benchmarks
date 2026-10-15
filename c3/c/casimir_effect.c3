module casimir_effect;

const double INVALID_RESULT = -1.0e300;
const double REDUCED_PLANCK_CONSTANT = 1.054571817e-34;
const double SPEED_OF_LIGHT = 3.0e8;
const double PI_VALUE = 3.14159265358979323846;
extern fn double pow(double base, double exponent);

fn double casimir_effect(long* values, usz length) @export("casimir_effect") {
    if (values == null || length != 3) return INVALID_RESULT;
    long force_units = values[0];
    long area_units = values[1];
    long distance_units = values[2];
    if (force_units < 0 || force_units > 1000000 || area_units < 0 || area_units > 1000000 ||
        distance_units < 0 || distance_units > 1000000) return INVALID_RESULT;
    int zero_count = 0;
    if (force_units == 0) zero_count++;
    if (area_units == 0) zero_count++;
    if (distance_units == 0) zero_count++;
    if (zero_count != 1) return INVALID_RESULT;
    double force = (double)force_units * 1.0e-12;
    double area = (double)area_units * 1.0e-6;
    double distance = (double)distance_units * 1.0e-6;
    if (force_units == 0)
        return (REDUCED_PLANCK_CONSTANT * SPEED_OF_LIGHT * pow(PI_VALUE, 2.0) * area) /
            (240.0 * pow(distance, 4.0));
    if (area_units == 0)
        return (240.0 * force * pow(distance, 4.0)) /
            (REDUCED_PLANCK_CONSTANT * SPEED_OF_LIGHT * pow(PI_VALUE, 2.0));
    return pow((REDUCED_PLANCK_CONSTANT * SPEED_OF_LIGHT * pow(PI_VALUE, 2.0) * area) /
        (240.0 * force), 0.25);
}
