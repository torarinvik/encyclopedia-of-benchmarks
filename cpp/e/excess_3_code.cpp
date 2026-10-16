#include <cstddef>
#include <cstdint>

extern "C" std::int64_t excess_3_code(std::int64_t value, std::uint8_t *output,
                                      std::size_t output_capacity) {
    std::uint8_t digits[19];
    std::size_t count = 0;
    std::uint64_t number = value < 0 ? 0 : static_cast<std::uint64_t>(value);
    do {
        digits[count++] = static_cast<std::uint8_t>(number % 10);
        number /= 10;
    } while (number != 0);
    const std::size_t output_length = 2 + 4 * count;
    if (output == nullptr || output_capacity < output_length) return -2;
    output[0] = '0';
    output[1] = 'b';
    std::size_t position = 2;
    while (count > 0) {
        const unsigned nibble = static_cast<unsigned>(digits[--count]) + 3U;
        for (unsigned bit = 8; bit != 0; bit >>= 1)
            output[position++] = static_cast<std::uint8_t>((nibble & bit) ? '1' : '0');
    }
    return static_cast<std::int64_t>(output_length);
}
