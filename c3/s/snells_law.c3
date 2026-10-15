module snells_law;

extern fn double sin(double value);
extern fn double asin(double value);
extern fn double fabs(double value);
extern fn double fmax(double left, double right);
extern fn double floor(double value);

const double INVALID_RESULT = -1.0e300;
const double PI = 3.141592653589793238462643383279502884;

fn double round_two_even(double value) {
    double scaled = value * 100.0;
    double lower = floor(scaled);
    double fraction = scaled - lower;
    long rounded = (long)lower;
    if (fraction > 0.5 || (fraction == 0.5 && rounded % 2 != 0)) rounded += 1;
    return (double)rounded / 100.0;
}

fn double snells_law(double n1, double n2, double incident_angle_degrees) @export("snells_law") {
    if (!(n1 >= 0.5 && n1 <= 2.5) || !(n2 >= 0.5 && n2 <= 2.5) ||
        !(incident_angle_degrees >= -90.0 && incident_angle_degrees <= 90.0)) return INVALID_RESULT;
    double incident_angle_radians = incident_angle_degrees * (PI / 180.0);
    double refraction_sine = (n1 / n2) * sin(incident_angle_radians);
    double scale = fmax(fabs(refraction_sine), 1.0);
    if (fabs(refraction_sine - 1.0) <= 1.0e-9 * scale) return 90.0;
    if (fabs(refraction_sine + 1.0) <= 1.0e-9 * scale) return -90.0;
    if (!(refraction_sine >= -1.0 && refraction_sine <= 1.0)) return INVALID_RESULT;
    double refraction_angle_degrees = asin(refraction_sine) * (180.0 / PI);
    return round_two_even(refraction_angle_degrees);
}
