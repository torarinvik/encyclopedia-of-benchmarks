#include <stddef.h>
#include <stdint.h>

int64_t plus_one(const int64_t *digits, size_t length, uint8_t *output, size_t output_capacity) {
    if (length > 256 || (length != 0 && digits == NULL)) return -1;
    int all_nines = 1;
    for (size_t index = 0; index < length; ++index) {
        if (digits[index] < 0 || digits[index] > 9) return -1;
        if (digits[index] != 9) all_nines = 0;
    }
    if (length > 1 && digits[0] == 0) return -1;
    const size_t output_length = length == 0 || all_nines ? length + 1 : length;
    if (output_capacity < output_length) return -2;
    if (length == 0 || all_nines) {
        output[0] = (uint8_t)'1';
        for (size_t index = 1; index < output_length; ++index) output[index] = (uint8_t)'0';
        return (int64_t)output_length;
    }
    for (size_t index = 0; index < length; ++index)
        output[index] = (uint8_t)('0' + digits[index]);
    for (size_t index = length; index > 0; --index) {
        if (digits[index - 1] == 9) output[index - 1] = (uint8_t)'0';
        else {
            output[index - 1] = (uint8_t)(output[index - 1] + 1);
            break;
        }
    }
    return (int64_t)output_length;
}
