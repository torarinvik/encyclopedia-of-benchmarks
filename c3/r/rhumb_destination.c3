module rhumb_destination;

extern fn double tan(double value);
extern fn double log(double value);
extern fn double sin(double value);
extern fn double cos(double value);

const double PI = 3.14159265358979323846264338327950288;
const double EARTH_RADIUS = 6371000.0;

bool finite_value(double value) { return value == value && value >= -1e308 && value <= 1e308; }

fn long rhumb_destination(double* input, usz input_length, double* output, usz output_capacity)
    @export("rhumb_destination") {
    if (input == null || input_length != 4) return -1;
    double latitude = input[0], longitude = input[1], distance = input[2], bearing = input[3];
    if (!finite_value(latitude) || !finite_value(longitude) || !finite_value(distance) || !finite_value(bearing) ||
        latitude < -80.0 || latitude > 80.0 || longitude < -180.0 || longitude > 180.0 ||
        distance < 0.0 || distance > 300000.0 || bearing < 0.0 || bearing > 360.0) return -1;
    double del = distance / EARTH_RADIUS;
    double phi1 = latitude * PI / 180.0;
    double lambda1 = longitude * PI / 180.0;
    double theta = bearing * PI / 180.0;
    double del_phi = del * cos(theta);
    double phi2 = phi1 + del_phi;
    if (phi2 > PI / 2.0) phi2 = PI / 2.0;
    else if (phi2 < -PI / 2.0) phi2 = -PI / 2.0;
    double del_psi = log(tan(phi2 / 2.0 + PI / 4.0) / tan(phi1 / 2.0 + PI / 4.0));
    double q = del_psi > 1e-12 || del_psi < -1e-12 ? del_phi / del_psi : cos(phi1);
    double del_lambda = del * sin(theta) / q;
    double result_latitude = phi2 * 180.0 / PI;
    double result_longitude = (lambda1 + del_lambda) * 180.0 / PI;
    if (output == null || output_capacity < 2) return -2;
    output[0] = result_latitude; output[1] = result_longitude;
    return 2;
}
