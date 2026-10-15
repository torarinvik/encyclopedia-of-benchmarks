module magnetic_flux;

const double INVALID_RESULT = -1.0e300;
const double PI_VALUE = 3.14159265358979323846;
extern fn double cos(double value);
extern fn double round(double value);

fn double magnetic_flux(long* values, usz length) @export("magnetic_flux") {
    if (values == null || length != 3) return INVALID_RESULT;
    long magnetic_field = values[0];
    long area = values[1];
    long angle = values[2];
    if (magnetic_field < 0 || magnetic_field > 10000 || area < 0 || area > 10000 ||
        (angle != 0 && angle != 60 && angle != 90 && angle != 120 && angle != 180)) return INVALID_RESULT;
    double radians = (double)angle * (PI_VALUE / 180.0);
    double flux = (double)magnetic_field * (double)area * cos(radians);
    return round(flux * 10.0) / 10.0;
}
