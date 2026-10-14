#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 256;
constexpr std::size_t max_input_values = 1 + 2 * max_values;
constexpr std::int64_t numerator_limit = 1'000'000'000'000;
constexpr std::int64_t denominator_limit = 1'000'000;
constexpr std::int64_t result_offset = 1'000'000'000'001;

std::int64_t ceil_division(std::int64_t numerator, std::int64_t denominator)
{
    if (numerator >= 0) return numerator / denominator + (numerator % denominator != 0);
    return -((-numerator) / denominator);
}
}

extern "C" std::int64_t ceil_benchmark(const std::int64_t *values, std::size_t length)
{
    if (length < 1 || length > max_input_values) return -1;
    const std::int64_t count_value = values[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(max_values)) return -1;
    const std::size_t count = static_cast<std::size_t>(count_value);
    if (length != 1 + 2 * count) return -1;
    for (std::size_t i = 0; i < count; ++i) {
        const std::int64_t numerator = values[1 + 2 * i];
        const std::int64_t denominator = values[2 + 2 * i];
        if (numerator < -numerator_limit || numerator > numerator_limit ||
            denominator < 1 || denominator > denominator_limit) return -1;
    }
    std::int64_t checksum = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const std::int64_t result = ceil_division(values[1 + 2 * i], values[2 + 2 * i]);
        checksum += static_cast<std::int64_t>(i + 1) * (result + result_offset);
    }
    return checksum;
}
