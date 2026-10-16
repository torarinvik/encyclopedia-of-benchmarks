#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_items = 512;
constexpr std::size_t table_size = 2048;

std::size_t slot_for(std::int64_t value) noexcept {
    const auto magnitude = value < 0 ? -value : value;
    return static_cast<std::size_t>(magnitude % static_cast<std::int64_t>(table_size));
}
}

extern "C" std::int64_t subarray_sum_equals_k(const std::int64_t *input, std::size_t length) noexcept {
    constexpr auto invalid_result = std::numeric_limits<std::int64_t>::min();
    constexpr auto minimum_i32 = static_cast<std::int64_t>(std::numeric_limits<std::int32_t>::min());
    constexpr auto maximum_i32 = static_cast<std::int64_t>(std::numeric_limits<std::int32_t>::max());
    if (input == nullptr || length < 2 || length > max_items + 2) return invalid_result;
    const auto count_value = input[0];
    const auto target = input[1];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(max_items) ||
        target < minimum_i32 || target > maximum_i32) return invalid_result;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != count + 2) return invalid_result;
    for (std::size_t index = 0; index < count; ++index) {
        if (input[index + 2] < minimum_i32 || input[index + 2] > maximum_i32) return invalid_result;
    }

    std::int64_t keys[table_size]{};
    std::int64_t frequencies[table_size]{};
    frequencies[0] = 1;
    std::int64_t prefix_sum = 0;
    std::int64_t result = 0;
    for (std::size_t index = 0; index < count; ++index) {
        prefix_sum += input[index + 2];
        const auto required = prefix_sum - target;
        auto slot = slot_for(required);
        while (frequencies[slot] != 0 && keys[slot] != required) slot = (slot + 1) % table_size;
        result += frequencies[slot];

        slot = slot_for(prefix_sum);
        while (frequencies[slot] != 0 && keys[slot] != prefix_sum) slot = (slot + 1) % table_size;
        if (frequencies[slot] == 0) keys[slot] = prefix_sum;
        ++frequencies[slot];
    }
    return result;
}
