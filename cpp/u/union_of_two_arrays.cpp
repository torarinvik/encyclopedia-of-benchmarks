#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ARRAY_LENGTH = 64;
constexpr std::size_t MAX_INPUT_LENGTH = 2 * (MAX_ARRAY_LENGTH + 1);
constexpr std::size_t BYTES_PER_VALUE = 4;

void store_i32_le(std::uint8_t *output, std::size_t position, std::int64_t value) {
    const std::uint32_t bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    for (std::size_t byte = 0; byte < BYTES_PER_VALUE; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t union_of_two_arrays(const std::int64_t *input, std::size_t length,
                                                      std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const std::int64_t first_length_value = input[0];
    if (first_length_value < 0 || first_length_value > static_cast<std::int64_t>(MAX_ARRAY_LENGTH)) return -1;
    const std::size_t first_length = static_cast<std::size_t>(first_length_value);
    const std::size_t second_length_position = 1 + first_length;
    if (second_length_position >= length) return -1;
    const std::int64_t second_length_value = input[second_length_position];
    if (second_length_value < 0 || second_length_value > static_cast<std::int64_t>(MAX_ARRAY_LENGTH)) return -1;
    const std::size_t second_length = static_cast<std::size_t>(second_length_value);
    const std::size_t second_start = second_length_position + 1;
    if (second_length != length - second_start) return -1;

    for (std::size_t index = 0; index < first_length; ++index) {
        const std::int64_t value = input[1 + index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        if (index > 0 && input[index] > value) return -1;
    }
    for (std::size_t index = 0; index < second_length; ++index) {
        const std::int64_t value = input[second_start + index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        if (index > 0 && input[second_start + index - 1] > value) return -1;
    }

    const std::size_t maximum_result = first_length + second_length;
    if (output_capacity < maximum_result * BYTES_PER_VALUE || (maximum_result > 0 && output == nullptr)) return -2;
    std::size_t first_index = 0, second_index = 0, result_count = 0;
    std::int64_t previous_value = 0;
    while (first_index < first_length || second_index < second_length) {
        std::int64_t value;
        if (first_index == first_length) {
            value = input[second_start + second_index++];
        } else if (second_index == second_length) {
            value = input[1 + first_index++];
        } else {
            const std::int64_t first = input[1 + first_index];
            const std::int64_t second = input[second_start + second_index];
            if (first < second) {
                value = first;
                ++first_index;
            } else if (first > second) {
                value = second;
                ++second_index;
            } else {
                value = first;
                ++first_index;
                ++second_index;
            }
        }
        if (result_count == 0 || value != previous_value) {
            store_i32_le(output, result_count * BYTES_PER_VALUE, value);
            previous_value = value;
            ++result_count;
        }
    }
    return static_cast<std::int64_t>(result_count);
}
