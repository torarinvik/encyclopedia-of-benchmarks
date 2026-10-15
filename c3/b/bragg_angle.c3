module bragg_angle;

extern fn double asin(double value);
extern fn double floor(double value);
const double INVALID_RESULT = -1.0e300;
const double PI = 3.141592653589793238462643383279502884;

fn double round_one_even(double value) {
    double scaled = value * 10.0;
    double lower = floor(scaled);
    double fraction = scaled - lower;
    long rounded = (long)lower;
    if (fraction > 0.5 || (fraction == 0.5 && rounded % 2 != 0)) rounded += 1;
    return (double)rounded / 10.0;
}

fn double bragg_angle(long* values, usz length) @export("bragg_angle") {
    if (values == null || length != 3) return INVALID_RESULT;
    long distance = values[0], order = values[1], wavelength = values[2];
    if (distance < 1 || distance > 1000000 || order < -1000 || order > 1000 || wavelength < 0 || wavelength > 1000000) return INVALID_RESULT;
    double sine = ((double)order * (double)wavelength) / (2.0 * (double)distance);
    if (sine < -1.0 || sine > 1.0) return INVALID_RESULT;
    double degrees = asin(sine) * (180.0 / PI);
    return round_one_even(degrees);
}
