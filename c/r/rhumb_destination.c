#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define PI 3.14159265358979323846264338327950288
#define EARTH_RADIUS 6371000.0

int64_t rhumb_destination(const double *input, size_t input_length,
                          double *output, size_t output_capacity) {
    if (input == NULL || input_length != 4) return -1;
    const double latitude = input[0], longitude = input[1], distance = input[2], bearing = input[3];
    if (!isfinite(latitude) || !isfinite(longitude) || !isfinite(distance) || !isfinite(bearing) ||
        latitude < -80.0 || latitude > 80.0 || longitude < -180.0 || longitude > 180.0 ||
        distance < 0.0 || distance > 300000.0 || bearing < 0.0 || bearing > 360.0) return -1;
    const double del = distance / EARTH_RADIUS;
    const double phi1 = latitude * PI / 180.0;
    const double lambda1 = longitude * PI / 180.0;
    const double theta = bearing * PI / 180.0;
    const double del_phi = del * cos(theta);
    double phi2 = phi1 + del_phi;
    if (phi2 > PI / 2.0) phi2 = PI / 2.0;
    else if (phi2 < -PI / 2.0) phi2 = -PI / 2.0;
    const double del_psi = log(tan(phi2 / 2.0 + PI / 4.0) / tan(phi1 / 2.0 + PI / 4.0));
    const double q = fabs(del_psi) > 1e-12 ? del_phi / del_psi : cos(phi1);
    const double del_lambda = del * sin(theta) / q;
    const double result[2] = {(phi2 * 180.0 / PI), (lambda1 + del_lambda) * 180.0 / PI};
    if (output == NULL || output_capacity < 2) return -2;
    output[0] = result[0]; output[1] = result[1];
    return 2;
}
