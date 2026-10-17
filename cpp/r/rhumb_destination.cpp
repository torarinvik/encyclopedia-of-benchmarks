#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double pi = 3.14159265358979323846264338327950288;
constexpr double earth_radius = 6371000.0;
}

extern "C" std::int64_t rhumb_destination(const double* input, std::size_t input_length,
                                           double* output, std::size_t output_capacity) {
    if (input == nullptr || input_length != 4) return -1;
    const double latitude = input[0], longitude = input[1], distance = input[2], bearing = input[3];
    if (!std::isfinite(latitude) || !std::isfinite(longitude) || !std::isfinite(distance) || !std::isfinite(bearing) ||
        latitude < -80.0 || latitude > 80.0 || longitude < -180.0 || longitude > 180.0 ||
        distance < 0.0 || distance > 300000.0 || bearing < 0.0 || bearing > 360.0) return -1;
    const double del = distance / earth_radius;
    const double phi1 = latitude * pi / 180.0;
    const double lambda1 = longitude * pi / 180.0;
    const double theta = bearing * pi / 180.0;
    const double del_phi = del * std::cos(theta);
    double phi2 = phi1 + del_phi;
    if (phi2 > pi / 2.0) phi2 = pi / 2.0;
    else if (phi2 < -pi / 2.0) phi2 = -pi / 2.0;
    const double del_psi = std::log(std::tan(phi2 / 2.0 + pi / 4.0) / std::tan(phi1 / 2.0 + pi / 4.0));
    const double q = std::abs(del_psi) > 1e-12 ? del_phi / del_psi : std::cos(phi1);
    const double del_lambda = del * std::sin(theta) / q;
    const double result[2] = {phi2 * 180.0 / pi, (lambda1 + del_lambda) * 180.0 / pi};
    if (output == nullptr || output_capacity < 2) return -2;
    output[0] = result[0]; output[1] = result[1];
    return 2;
}
