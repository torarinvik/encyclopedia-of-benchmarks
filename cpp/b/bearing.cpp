// Return a spherical initial bearing in integer microdegrees.
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t bearing(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length != 4) return -1;
    const auto latitude1_value = values[0];
    const auto longitude1_value = values[1];
    const auto latitude2_value = values[2];
    const auto longitude2_value = values[3];
    if (latitude1_value < -90000000 || latitude1_value > 90000000 ||
        latitude2_value < -90000000 || latitude2_value > 90000000 ||
        longitude1_value < -180000000 || longitude1_value > 180000000 ||
        longitude2_value < -180000000 || longitude2_value > 180000000 ||
        (latitude1_value == latitude2_value && longitude1_value == longitude2_value)) {
        return -1;
    }

    constexpr double radians_per_microdegree = 0.000001 * (3.14159265358979323846 / 180.0);
    const double latitude1 = static_cast<double>(latitude1_value) * radians_per_microdegree;
    const double longitude1 = static_cast<double>(longitude1_value) * radians_per_microdegree;
    const double latitude2 = static_cast<double>(latitude2_value) * radians_per_microdegree;
    const double longitude2 = static_cast<double>(longitude2_value) * radians_per_microdegree;
    const double delta_longitude = longitude2 - longitude1;
    const double east = std::sin(delta_longitude) * std::cos(latitude2);
    const double north = std::cos(latitude1) * std::sin(latitude2) -
                         std::sin(latitude1) * std::cos(latitude2) * std::cos(delta_longitude);
    double degrees = std::atan2(east, north) * 57.2957795130823208768;
    if (degrees < 0.0) degrees += 360.0;
    const auto result = static_cast<std::int64_t>(degrees * 1000000.0 + 0.5);
    return result >= 360000000 ? 0 : result;
}
