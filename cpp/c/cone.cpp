// Selected volume or total surface area of a circular cone.
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double PI = 3.14159265358979323846; constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double cone(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return INVALID_RESULT;
    const auto operation = values[0];
    const auto radius = values[1];
    const auto height = values[2];
    if ((operation != 0 && operation != 1) || radius < 0 || radius > 1000 ||
        height < 0 || height > 1000) return INVALID_RESULT;
    const double radius_value = static_cast<double>(radius);
    const double radius_squared = radius_value * radius_value;
    const double base_area = radius_squared * PI;
    if (operation == 0) return (base_area * static_cast<double>(height) * 1.0) / 3.0;
    const double height_value = static_cast<double>(height);
    return base_area + PI * radius_value * std::sqrt(radius_squared + height_value * height_value);
}
