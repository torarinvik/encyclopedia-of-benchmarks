#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_array_length = 256;
constexpr std::size_t max_input_length = max_array_length + 1;
constexpr std::int64_t int32_min_value = -2147483647LL - 1;
constexpr std::int64_t int32_max_value = 2147483647LL;
}

extern "C" std::int64_t how_many_times_rotated(const std::int64_t *input,
    std::size_t length) noexcept {
    if (length > max_input_length) return -1;
    if (length > max_array_length) return -1;
    if (length == 0) return 0;
    if (input == nullptr) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < int32_min_value || input[index] > int32_max_value) return -1;

    std::size_t low = 0;
    std::size_t high = length == 0 ? 0 : length - 1;
    while (low < high) {
        const std::size_t middle = low + (high - low) / 2;
        if (input[middle] > input[high]) low = middle + 1;
        else high = middle;
    }
    return static_cast<std::int64_t>(low);
}
