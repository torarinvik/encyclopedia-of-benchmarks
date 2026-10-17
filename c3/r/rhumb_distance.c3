module rhumb_distance;

extern fn double tan(double value);
extern fn double log(double value);
extern fn double cos(double value);
extern fn double sqrt(double value);
extern fn double pow(double base, double exponent);

const double PI = 3.14159265358979323846264338327950288;
const double EARTH_RADIUS = 6371000.0;

bool finite_value(double value) { return value == value && value >= -1e308 && value <= 1e308; }

fn long rhumb_distance(double* input, usz input_length, double* output, usz output_capacity)
    @export("rhumb_distance") {
    if (input == null || input_length != 4) return -1;
    double lat1 = input[0], long1 = input[1], lat2 = input[2], long2 = input[3];
    if (!finite_value(lat1) || !finite_value(long1) || !finite_value(lat2) || !finite_value(long2) ||
        lat1 < -85.0 || lat1 > 85.0 || lat2 < -85.0 || lat2 > 85.0 ||
        long1 < -180.0 || long1 > 180.0 || long2 < -180.0 || long2 > 180.0) return -1;
    double phi1 = lat1 * PI / 180.0;
    double phi2 = lat2 * PI / 180.0;
    double del_phi = phi2 - phi1;
    double del_lambda = (long2 - long1) * PI / 180.0;
    if (del_lambda > PI) del_lambda -= 2.0 * PI;
    else if (del_lambda < -PI) del_lambda += 2.0 * PI;
    double del_psi = log(tan(phi2 / 2.0 + PI / 4.0) / tan(phi1 / 2.0 + PI / 4.0));
    double q = del_psi > 1e-12 || del_psi < -1e-12 ? del_phi / del_psi : cos(phi1);
    double distance = sqrt(pow(del_phi, 2.0) + pow(q * del_lambda, 2.0)) * EARTH_RADIUS;
    if (output == null || output_capacity < 1) return -2;
    output[0] = distance;
    return 1;
}
