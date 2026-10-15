#include <cstddef>
#include <cstdint>
#include <cstring>

static std::size_t unsigned_bits(std::uint32_t value, char *bits)
{
    std::size_t length = 0;
    do { bits[length++] = static_cast<char>('0' + (value & 1u)); value >>= 1; }
    while (value != 0);
    for (std::size_t left = 0, right = length - 1; left < right; ++left, --right) {
        const char temporary = bits[left]; bits[left] = bits[right]; bits[right] = temporary;
    }
    return length;
}

extern "C" std::int64_t binary_shifts(const std::int64_t *values, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length != 3) return -1;
    const auto operation = values[0], number = values[1], shift = values[2];
    if (operation < 0 || operation > 2 || number < -2147483647LL || number > 2147483647LL ||
        shift < 0 || shift > 31 || (operation < 2 && number < 0)) return -1;
    char bits[80], result[82];
    std::size_t bits_length = 0, result_length = 0;
    if (operation == 0 || operation == 1) {
        bits_length = unsigned_bits(static_cast<std::uint32_t>(number), bits);
        result[result_length++] = '0'; result[result_length++] = 'b';
        if (operation == 0) {
            std::memcpy(result + result_length, bits, bits_length); result_length += bits_length;
            for (std::int64_t i = 0; i < shift; ++i) result[result_length++] = '0';
        } else if (static_cast<std::size_t>(shift) >= bits_length) result[result_length++] = '0';
        else {
            const auto kept = bits_length - static_cast<std::size_t>(shift);
            std::memcpy(result + result_length, bits, kept); result_length += kept;
        }
    } else {
        if (number >= 0) {
            bits[0] = '0'; bits_length = 1 + unsigned_bits(static_cast<std::uint32_t>(number), bits + 1);
        } else {
            const auto magnitude = static_cast<std::uint32_t>(-number);
            const auto magnitude_length = unsigned_bits(magnitude, bits);
            const auto complement = (UINT32_C(1) << magnitude_length) - magnitude;
            char complement_bits[40];
            const auto complement_length = unsigned_bits(complement, complement_bits);
            bits[0] = '1'; std::size_t position = 1;
            for (std::size_t i = complement_length; i < magnitude_length; ++i) bits[position++] = '0';
            std::memcpy(bits + position, complement_bits, complement_length);
            bits_length = position + complement_length;
        }
        const char sign = bits[0]; result[result_length++] = '0'; result[result_length++] = 'b';
        if (static_cast<std::size_t>(shift) >= bits_length)
            for (std::size_t i = 0; i < bits_length; ++i) result[result_length++] = sign;
        else {
            for (std::int64_t i = 0; i < shift; ++i) result[result_length++] = sign;
            const auto kept = bits_length - static_cast<std::size_t>(shift);
            std::memcpy(result + result_length, bits, kept); result_length += kept;
        }
    }
    if (output == nullptr || output_capacity < result_length) return -2;
    std::memcpy(output, result, result_length);
    return static_cast<std::int64_t>(result_length);
}
