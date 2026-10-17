module rhumb_bearing;

extern fn double tan(double value);
extern fn double log(double value);
extern fn double atan2(double y, double x);
extern fn double floor(double value);

const double PI = 3.14159265358979323846264338327950288;

bool finite_value(double value) { return value == value && value >= -1e308 && value <= 1e308; }

fn long rhumb_bearing(double* input, usz input_length, double* output, usz output_capacity)
    @export("rhumb_bearing") {
    if (input == null || input_length != 4) return -1;
    double lat1 = input[0], long1 = input[1], lat2 = input[2], long2 = input[3];
    if (!finite_value(lat1) || !finite_value(long1) || !finite_value(lat2) || !finite_value(long2) ||
        lat1 < -85.0 || lat1 > 85.0 || lat2 < -85.0 || lat2 > 85.0 ||
        long1 < -180.0 || long1 > 180.0 || long2 < -180.0 || long2 > 180.0) return -1;

    double phi1 = lat1 * PI / 180.0;
    double phi2 = lat2 * PI / 180.0;
    double del_lambda = (long2 - long1) * PI / 180.0;
    if (del_lambda > PI) del_lambda -= 2.0 * PI;
    else if (del_lambda < -PI) del_lambda += 2.0 * PI;
    double del_psi = log(tan(phi2 / 2.0 + PI / 4.0) / tan(phi1 / 2.0 + PI / 4.0));
    double bearing = atan2(del_lambda, del_psi) * 180.0 / PI;
    double bearing_plus_360 = bearing + 360.0;
    double normalized = bearing_plus_360 - floor(bearing_plus_360 / 360.0) * 360.0;
    if (output == null || output_capacity < 1) return -2;
    output[0] = normalized;
    return 1;
}
