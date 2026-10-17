#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double pi = 3.14159265358979323846264338327950288;
bool finite_value(double value) { return std::isfinite(value); }
}

extern "C" std::int64_t rhumb_bearing(const double* input, std::size_t input_length,
                                        double* output, std::size_t output_capacity) {
    if (input == nullptr || input_length != 4) return -1;
    const double lat1 = input[0], long1 = input[1], lat2 = input[2], long2 = input[3];
    if (!finite_value(lat1) || !finite_value(long1) || !finite_value(lat2) || !finite_value(long2) ||
        lat1 < -85.0 || lat1 > 85.0 || lat2 < -85.0 || lat2 > 85.0 ||
        long1 < -180.0 || long1 > 180.0 || long2 < -180.0 || long2 > 180.0) return -1;

    const double phi1 = lat1 * pi / 180.0;
    const double phi2 = lat2 * pi / 180.0;
    double del_lambda = (long2 - long1) * pi / 180.0;
    if (del_lambda > pi) del_lambda -= 2.0 * pi;
    else if (del_lambda < -pi) del_lambda += 2.0 * pi;
    const double del_psi = std::log(std::tan(phi2 / 2.0 + pi / 4.0) / std::tan(phi1 / 2.0 + pi / 4.0));
    const double bearing = std::atan2(del_lambda, del_psi) * 180.0 / pi;
    const double bearing_plus_360 = bearing + 360.0;
    const double normalized = bearing_plus_360 - std::floor(bearing_plus_360 / 360.0) * 360.0;

    if (output == nullptr || output_capacity < 1) return -2;
    output[0] = normalized;
    return 1;
}
