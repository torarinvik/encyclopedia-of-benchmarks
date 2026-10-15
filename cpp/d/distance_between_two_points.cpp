#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_COORDINATE = 1'000'000;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double distance_between_two_points(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length != 4) return INVALID_RESULT;
    for (std::size_t index = 0; index < 4; ++index) {
        if (values[index] < -MAX_COORDINATE || values[index] > MAX_COORDINATE) return INVALID_RESULT;
    }
    const double dx = static_cast<double>(values[2] - values[0]);
    const double dy = static_cast<double>(values[3] - values[1]);
    return std::sqrt(dx * dx + dy * dy);
}
