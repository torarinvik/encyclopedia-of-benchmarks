#include <cstddef>
#include <cstdint>

namespace { constexpr double INVALID_RESULT = -1.0e300; }
extern "C" double circular_arc(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 3) return INVALID_RESULT;
    const auto mode = input[0], radius = input[1], degrees = input[2];
    if ((mode != 0 && mode != 1) || radius < -1000000 || radius > 1000000 || degrees < -360000 || degrees > 360000) return INVALID_RESULT;
    constexpr double pi = 3.14159265358979323846;
    const double angle = static_cast<double>(degrees) * (pi / 180.0);
    if (mode == 0) return static_cast<double>(radius) * angle;
    return static_cast<double>(radius * radius) * angle / 2.0;
}
