#include <cstddef>
#include <cstdint>

namespace {
std::int64_t magnitude(std::int64_t value) { return value < 0 ? -value : value; }

std::int64_t select_absolute(const std::int64_t *values, std::size_t length, bool maximum)
{
    if (length < 2 || length > 257) return -1;
    const std::int64_t count_value = values[0];
    if (count_value < 1 || count_value > 256 || length != static_cast<std::size_t>(count_value) + 1) return -1;
    for (std::size_t index = 1; index < length; ++index) {
        if (values[index] < -1'000'000'000'000LL || values[index] > 1'000'000'000'000LL) return -1;
    }
    std::int64_t best = values[1];
    for (std::size_t index = 2; index < length; ++index) {
        const std::int64_t candidate = values[index];
        if (maximum ? magnitude(candidate) > magnitude(best) : magnitude(candidate) < magnitude(best)) best = candidate;
    }
    return best;
}
}

extern "C" std::int64_t abs_min_benchmark(const std::int64_t *values, std::size_t length)
{
    return select_absolute(values, length, false);
}
