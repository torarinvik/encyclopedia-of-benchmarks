/* Bounded integer port of the pinned floating-point Horner routine. */
#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" int64_t polynomial_evaluation(const int64_t *values, std::size_t length)
{
    constexpr int64_t invalid = std::numeric_limits<int64_t>::min();
    if (values == nullptr || length < 2 || length > 10) return invalid;
    const int64_t count = values[0];
    const int64_t x = values[1];
    if (count < 0 || count > 8 || length != static_cast<std::size_t>(count + 2)) return invalid;
    if (x < -10 || x > 10) return invalid;
    for (std::size_t index = 0; index < static_cast<std::size_t>(count); ++index) {
        if (values[index + 2] < -1000 || values[index + 2] > 1000) return invalid;
    }
    int64_t result = 0;
    for (std::size_t index = static_cast<std::size_t>(count); index > 0; --index) {
        result = result * x + values[index + 1];
    }
    return result;
}
