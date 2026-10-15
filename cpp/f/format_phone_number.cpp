#include <cstddef>
#include <cstdint>

extern "C" std::int64_t format_phone_number(const std::int64_t *values, std::size_t length,
                                             std::uint8_t *output, std::size_t output_capacity)
{
    if (values == nullptr || length != 10) return -1;
    for (std::size_t i = 0; i < 10; ++i) {
        if (values[i] < '0' || values[i] > '9') return -1;
    }
    if (output == nullptr || output_capacity < 14) return -2;

    output[0] = '(';
    output[1] = static_cast<std::uint8_t>(values[0]);
    output[2] = static_cast<std::uint8_t>(values[1]);
    output[3] = static_cast<std::uint8_t>(values[2]);
    output[4] = ')';
    output[5] = ' ';
    output[6] = static_cast<std::uint8_t>(values[3]);
    output[7] = static_cast<std::uint8_t>(values[4]);
    output[8] = static_cast<std::uint8_t>(values[5]);
    output[9] = '-';
    for (std::size_t i = 6; i < 10; ++i) output[10 + i - 6] = static_cast<std::uint8_t>(values[i]);
    return 14;
}
