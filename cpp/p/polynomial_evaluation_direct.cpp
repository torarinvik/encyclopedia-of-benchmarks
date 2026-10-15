/* Bounded integer port of the pinned direct-power polynomial routine. */
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
std::int64_t integer_power(std::int64_t base, std::size_t exponent) noexcept {
    std::int64_t result = 1;
    for (std::size_t index = 0; index < exponent; ++index) result *= base;
    return result;
}
}

extern "C" std::int64_t polynomial_evaluation_direct(const std::int64_t *values, std::size_t length) noexcept {
    constexpr std::int64_t invalid = std::numeric_limits<std::int64_t>::min();
    if (values == nullptr || length < 2 || length > 10) return invalid;
    const std::int64_t count = values[0];
    const std::int64_t x = values[1];
    if (count < 0 || count > 8 || length != static_cast<std::size_t>(count + 2)) return invalid;
    if (x < -10 || x > 10) return invalid;
    for (std::size_t index = 0; index < static_cast<std::size_t>(count); ++index) {
        if (values[index + 2] < -1000 || values[index + 2] > 1000) return invalid;
    }
    std::int64_t result = 0;
    for (std::size_t index = 0; index < static_cast<std::size_t>(count); ++index)
        result += values[index + 2] * integer_power(x, index);
    return result;
}
