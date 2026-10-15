#include <cstddef>
#include <cstdint>

extern "C" std::int64_t binary_to_hex(const std::int64_t *values, std::size_t length,
                                       std::uint8_t *output, std::size_t output_capacity)
{
    if (length > 4096 || (length != 0 && values == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] != '0' && values[i] != '1') return -1;
    }

    const std::size_t output_length = (length + 3) / 4;
    if (output_length == 0) return 0;
    if (output == nullptr || output_capacity < output_length) return -2;

    std::size_t first_width = length % 4;
    if (first_width == 0) first_width = 4;
    std::size_t start = 0;
    for (std::size_t group = 0; group < output_length; ++group) {
        const std::size_t width = group == 0 ? first_width : 4;
        int nibble = 0;
        for (std::size_t offset = 0; offset < width; ++offset) {
            nibble = nibble * 2 + static_cast<int>(values[start + offset] - '0');
        }
        output[group] = static_cast<std::uint8_t>(nibble < 10 ? '0' + nibble : 'A' + nibble - 10);
        start += width;
    }
    return static_cast<std::int64_t>(output_length);
}
