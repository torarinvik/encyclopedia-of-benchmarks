/* Add two most-significant-first binary digit arrays. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t binary_addition(const std::int64_t *values,
                                         std::size_t length,
                                         std::uint8_t *output,
                                         std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 2) return -1;

    const std::int64_t length_a_value = values[0];
    const std::int64_t length_b_value = values[1];
    if (length_a_value < 0 || length_a_value > 2047 ||
        length_b_value < 0 || length_b_value > 2047) return -1;

    const std::size_t length_a = static_cast<std::size_t>(length_a_value);
    const std::size_t length_b = static_cast<std::size_t>(length_b_value);
    if (length != 2 + length_a + length_b) return -1;

    for (std::size_t index = 0; index < length_a + length_b; ++index)
        if (values[2 + index] < 0 || values[2 + index] > 1) return -1;

    const std::size_t width = length_a > length_b ? length_a : length_b;
    int carry = 0;
    for (std::size_t offset = 0; offset < width; ++offset) {
        const int bit_a = offset < length_a
            ? static_cast<int>(values[2 + length_a - 1 - offset]) : 0;
        const int bit_b = offset < length_b
            ? static_cast<int>(values[2 + length_a + length_b - 1 - offset]) : 0;
        carry = (bit_a + bit_b + carry) >> 1;
    }
    const std::size_t result_length = width + static_cast<std::size_t>(carry);
    if (result_length == 0) return 0;
    if (output == nullptr || output_capacity < result_length) return -2;

    carry = 0;
    for (std::size_t offset = 0; offset < width; ++offset) {
        const int bit_a = offset < length_a
            ? static_cast<int>(values[2 + length_a - 1 - offset]) : 0;
        const int bit_b = offset < length_b
            ? static_cast<int>(values[2 + length_a + length_b - 1 - offset]) : 0;
        const int sum = bit_a + bit_b + carry;
        const std::size_t destination = result_length - 1 - offset;
        output[destination] = static_cast<std::uint8_t>('0' + (sum & 1));
        carry = sum >> 1;
    }
    if (carry != 0) output[0] = static_cast<std::uint8_t>('1');
    return static_cast<std::int64_t>(result_length);
}
