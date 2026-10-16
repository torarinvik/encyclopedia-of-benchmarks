#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" int64_t calculate_median(const int64_t *values, std::size_t length)
{
    constexpr int64_t invalid = std::numeric_limits<int64_t>::min();
    if (values == nullptr || length == 0 || length > 1024) return invalid;
    const std::size_t middle = length / 2;
    if (length % 2 != 0) return values[middle] * 2;
    return values[middle - 1] + values[middle];
}
