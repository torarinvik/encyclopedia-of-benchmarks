#include <stddef.h>
#include <stdint.h>

enum { MAX_CHARACTERS = 31, MAX_OUTPUT_BYTES = 1 + 2 * MAX_CHARACTERS };

int64_t misc_lowercase(const int64_t *input, size_t input_length,
                      uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1 || input_length > MAX_CHARACTERS + 2) return -1;
    const int64_t raw_length = input[0];
    if (raw_length < 0 || raw_length > MAX_CHARACTERS ||
        input_length != (size_t)raw_length + 1) return -1;
    const size_t length = (size_t)raw_length;
    uint16_t lowered[MAX_CHARACTERS];
    uint8_t ascii_flag = 1;
    for (size_t index = 0; index < length; ++index) {
        const int64_t raw = input[index + 1];
        if (raw < 0 || raw > 65535) return -1;
        const uint16_t value = (uint16_t)raw;
        if (value > 0x7f) ascii_flag = 0;
        lowered[index] = (uint16_t)(value | ((value >= 'A' && value <= 'Z') << 5));
    }
    const size_t required = 1 + 2 * length;
    if (output == NULL || output_capacity < required) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES];
    staged[0] = ascii_flag;
    for (size_t index = 0; index < length; ++index) {
        staged[1 + 2 * index] = (uint8_t)(lowered[index] & 0xff);
        staged[2 + 2 * index] = (uint8_t)(lowered[index] >> 8);
    }
    for (size_t index = 0; index < required; ++index) output[index] = staged[index];
    return (int64_t)required;
}
