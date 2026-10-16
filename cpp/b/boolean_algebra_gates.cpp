/* Evaluate the pinned Java source's Boolean gates over a flat 0/1 array. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_count = 4096;
constexpr std::int64_t invalid_result = -1;
}

extern "C" std::int64_t boolean_algebra_gates(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 2 || length > max_input_count + 2) return invalid_result;
    const std::int64_t gate = values[0];
    const std::int64_t count = values[1];
    if (gate < 0 || gate > 5 || count < 0 || count > 4096) return invalid_result;
    if (static_cast<std::size_t>(count) != length - 2) return invalid_result;
    if (gate == 2 && count != 1) return invalid_result;
    std::int64_t result = (gate == 0 || gate == 4) ? 1 : 0;
    for (std::size_t index = 0; index < static_cast<std::size_t>(count); ++index) {
        const std::int64_t bit = values[index + 2];
        if (bit != 0 && bit != 1) return invalid_result;
        if (gate == 0 || gate == 4) result &= bit;
        else if (gate == 1 || gate == 5) result |= bit;
        else if (gate == 2) result = 1 - bit;
        else result ^= bit;
    }
    if (gate == 4 || gate == 5) result = 1 - result;
    return result;
}
