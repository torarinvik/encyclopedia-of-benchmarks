#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
constexpr double PI_VALUE = 3.14159265358979323846264338327950288;

bool valid_coordinates(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length != 4) return false;
    if (values[0] < -90000000 || values[0] > 90000000) return false;
    if (values[2] < -90000000 || values[2] > 90000000) return false;
    if (values[1] < -180000000 || values[1] > 180000000) return false;
    if (values[3] < -180000000 || values[3] > 180000000) return false;
    return true;
}

double haversine_a(const std::int64_t *values) {
    const double radians_per_microdegree = PI_VALUE / 180000000.0;
    const double latitude1 = static_cast<double>(values[0]) * radians_per_microdegree;
    const double longitude1 = static_cast<double>(values[1]) * radians_per_microdegree;
    const double latitude2 = static_cast<double>(values[2]) * radians_per_microdegree;
    const double longitude2 = static_cast<double>(values[3]) * radians_per_microdegree;
    const double delta_latitude = latitude2 - latitude1;
    const double delta_longitude = longitude2 - longitude1;
    const double sin_latitude = std::sin(delta_latitude / 2.0);
    const double sin_longitude = std::sin(delta_longitude / 2.0);
    double a = sin_latitude * sin_latitude +
        std::cos(latitude1) * std::cos(latitude2) * sin_longitude * sin_longitude;
    if (a < 0.0) a = 0.0;
    if (a > 1.0) a = 1.0;
    return a;
}
}

extern "C" double haversine_rust_variant(const std::int64_t *values, std::size_t length) noexcept {
    if (!valid_coordinates(values, length)) return INVALID_RESULT;
    const double a = haversine_a(values);
    return 2.0 * std::sqrt(std::asin(a)) * 6371000.0;
}
