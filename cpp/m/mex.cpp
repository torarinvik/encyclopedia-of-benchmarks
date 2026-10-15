#include <algorithm>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t mex(const std::int64_t *input, std::size_t length)
{
    constexpr std::size_t max_values = 100000;
    if (input == nullptr || length < 1 || length > max_values + 1) return -1;
    const std::int64_t count_value = input[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(max_values) ||
        length != static_cast<std::size_t>(count_value) + 1) return -1;
    const std::size_t count = static_cast<std::size_t>(count_value);
    std::int64_t values[max_values];
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t value = input[index + 1];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        values[index] = value;
    }
    std::sort(values, values + count);
    std::int64_t candidate = 0;
    for (std::size_t index = 0; index < count; ++index) {
        if (values[index] == candidate) ++candidate;
    }
    return candidate;
}
