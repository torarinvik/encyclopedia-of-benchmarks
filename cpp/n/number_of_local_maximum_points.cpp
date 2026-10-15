#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_LENGTH = 4096;
constexpr std::int64_t INT32_MIN_VALUE = -INT64_C(2147483648);
constexpr std::int64_t INT32_MAX_VALUE = INT64_C(2147483647);

bool is_local_maximum(const std::int64_t *values, std::int64_t length, std::int64_t index)
{
    if (index == 0) return values[0] > values[1];
    if (index == length - 1) return values[index] > values[index - 1];
    return values[index] > values[index - 1] && values[index] > values[index + 1];
}

std::int64_t count_range(const std::int64_t *values, std::int64_t length, std::int64_t start, std::int64_t end)
{
    if (start == end) return is_local_maximum(values, length, start) ? 1 : 0;
    const std::int64_t middle = (start + end) / 2;
    return count_range(values, length, start, middle) + count_range(values, length, middle + 1, end);
}
}

// Count strict local maxima using the pinned recursive partition.
extern "C" std::int64_t number_of_local_maximum_points(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length == 0 || length > MAX_LENGTH) return -1;
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] < INT32_MIN_VALUE || values[i] > INT32_MAX_VALUE) return -1;
    }
    if (length == 1) return 0; // Source compares the sole element with undefined.
    return count_range(values, static_cast<std::int64_t>(length), 0, static_cast<std::int64_t>(length) - 1);
}
