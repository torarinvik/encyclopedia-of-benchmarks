// Intersection of three strictly increasing arrays, in ascending order.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t array_count = 3;
constexpr std::size_t max_array_length = 64;
constexpr std::size_t bytes_per_value = 4;

void store_i32_le(std::uint8_t *output, std::size_t position, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < bytes_per_value; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t sorted_arrays_intersection(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < array_count || length > array_count * (max_array_length + 1)) return -1;
    std::size_t starts[array_count], sizes[array_count], position = 0;
    for (std::size_t array = 0; array < array_count; ++array) {
        if (position >= length || input[position] < 0 || input[position] > static_cast<std::int64_t>(max_array_length)) return -1;
        const auto size = static_cast<std::size_t>(input[position++]);
        if (size > length - position) return -1;
        starts[array] = position; sizes[array] = size;
        for (std::size_t index = 0; index < size; ++index) {
            if (input[position + index] < std::numeric_limits<std::int32_t>::min() ||
                input[position + index] > std::numeric_limits<std::int32_t>::max()) return -1;
            if (index > 0 && input[position + index - 1] >= input[position + index]) return -1;
        }
        position += size;
    }
    if (position != length) return -1;
    const auto maximum_result = sizes[0] < sizes[1]
        ? (sizes[0] < sizes[2] ? sizes[0] : sizes[2])
        : (sizes[1] < sizes[2] ? sizes[1] : sizes[2]);
    if (output_capacity < maximum_result * bytes_per_value || (maximum_result != 0 && output == nullptr)) return -2;

    std::size_t cursor[array_count]{};
    std::size_t result_count = 0;
    while (cursor[0] < sizes[0] && cursor[1] < sizes[1] && cursor[2] < sizes[2]) {
        const auto first = input[starts[0] + cursor[0]];
        const auto second = input[starts[1] + cursor[1]];
        const auto third = input[starts[2] + cursor[2]];
        if (first == second && first == third) {
            store_i32_le(output, result_count * bytes_per_value, first);
            ++result_count; ++cursor[0]; ++cursor[1]; ++cursor[2];
        } else if (first < second) {
            ++cursor[0];
        } else if (second < third) {
            ++cursor[1];
        } else {
            ++cursor[2];
        }
    }
    return static_cast<std::int64_t>(result_count);
}
