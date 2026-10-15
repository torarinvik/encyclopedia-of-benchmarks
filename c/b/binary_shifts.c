#include <stddef.h>
#include <stdint.h>
#include <string.h>

static size_t unsigned_bits(uint32_t value, char *bits)
{
    size_t length = 0;
    do {
        bits[length++] = (char)('0' + (value & 1u));
        value >>= 1;
    } while (value != 0);
    for (size_t left = 0, right = length - 1; left < right; ++left, --right) {
        char temporary = bits[left]; bits[left] = bits[right]; bits[right] = temporary;
    }
    return length;
}

int64_t binary_shifts(const int64_t *values, size_t length, uint8_t *output,
                      size_t output_capacity)
{
    if (values == NULL || length != 3) return -1;
    const int64_t operation = values[0], number = values[1], shift_value = values[2];
    if (operation < 0 || operation > 2 || number < -2147483647LL || number > 2147483647LL ||
        shift_value < 0 || shift_value > 31 ||
        (operation < 2 && number < 0)) return -1;

    char bits[80], result[82];
    size_t bits_length = 0, result_length = 0;
    if (operation == 0 || operation == 1) {
        bits_length = unsigned_bits((uint32_t)number, bits);
        result[result_length++] = '0'; result[result_length++] = 'b';
        if (operation == 0) {
            memcpy(result + result_length, bits, bits_length); result_length += bits_length;
            for (int64_t i = 0; i < shift_value; ++i) result[result_length++] = '0';
        } else if ((size_t)shift_value >= bits_length) {
            result[result_length++] = '0';
        } else {
            const size_t kept = bits_length - (size_t)shift_value;
            memcpy(result + result_length, bits, kept); result_length += kept;
        }
    } else {
        if (number >= 0) {
            bits[0] = '0';
            bits_length = 1 + unsigned_bits((uint32_t)number, bits + 1);
        } else {
            const uint32_t magnitude = (uint32_t)(-number);
            const size_t magnitude_length = unsigned_bits(magnitude, bits);
            const uint32_t complement = (UINT32_C(1) << magnitude_length) - magnitude;
            char complement_bits[40];
            const size_t complement_length = unsigned_bits(complement, complement_bits);
            bits[0] = '1';
            size_t position = 1;
            for (size_t i = complement_length; i < magnitude_length; ++i) bits[position++] = '0';
            memcpy(bits + position, complement_bits, complement_length);
            bits_length = position + complement_length;
        }
        const char sign = bits[0];
        result[result_length++] = '0'; result[result_length++] = 'b';
        if ((size_t)shift_value >= bits_length) {
            for (size_t i = 0; i < bits_length; ++i) result[result_length++] = sign;
        } else {
            for (int64_t i = 0; i < shift_value; ++i) result[result_length++] = sign;
            const size_t kept = bits_length - (size_t)shift_value;
            memcpy(result + result_length, bits, kept); result_length += kept;
        }
    }
    if (output == NULL || output_capacity < result_length) return -2;
    memcpy(output, result, result_length);
    return (int64_t)result_length;
}
