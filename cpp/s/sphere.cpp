#include <cstddef>
#include <cstdint>
namespace { constexpr double INVALID_RESULT = -1.0e300; }
extern "C" double sphere(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 2) return INVALID_RESULT;
    const auto mode = input[0], radius = input[1];
    if ((mode != 0 && mode != 1) || radius < 0 || radius > 1000000) return INVALID_RESULT;
    const double r = static_cast<double>(radius);
    const double r2 = r * r;
    if (mode == 0) return (((r2 * r) * 3.14159265358979323846) * 4.0) / 3.0;
    return (r2 * 3.14159265358979323846) * 4.0;
}
