#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t liu_hui_pi_approximation(const std::int64_t* values, std::size_t length) noexcept
{
    if (values == nullptr || length != 1) return -1;
    const std::int64_t doublings = values[0];
    if (doublings < 0 || doublings > 16) return -1;

    std::int64_t sides = 6;
    double side = 1.0;
    double apothem = std::sqrt(0.75);
    for (std::int64_t i = 0; i < doublings; ++i) {
        const double half_side = side / 2.0;
        const double height = 1.0 - apothem;
        side = std::sqrt(half_side * half_side + height * height);
        sides *= 2;
        const double next_half_side = side / 2.0;
        apothem = std::sqrt(1.0 - next_half_side * next_half_side);
    }

    const double area = static_cast<double>(sides) * side * apothem / 2.0;
    return static_cast<std::int64_t>(area * 1000000.0 + 0.5);
}
