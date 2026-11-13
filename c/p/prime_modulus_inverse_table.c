#include <stddef.h>
#include <stdint.h>

int64_t prime_modulus_inverse_table(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    const int64_t modulus = INT64_C(1000000007);
    if (input == NULL || length < 1 || length > 34) return -1;
    int64_t count_value = input[0];
    if (count_value < 0 || count_value > 32) return -1;
    size_t count = (size_t)count_value;
    if (length != count + 1) return -1;
    size_t maximum = 0;
    for (size_t i = 0; i < count; ++i) {
        if (input[i + 1] < 1 || input[i + 1] > 256) return -1;
        if ((size_t)input[i + 1] > maximum) maximum = (size_t)input[i + 1];
    }
    if (count == 0) return 0;
    size_t bytes = 4 * count;
    if (output == NULL || capacity < bytes) return -2;
    int64_t inverse[257] = {0};
    inverse[1] = 1;
    for (size_t i = 2; i <= maximum; ++i) {
        int64_t value = (int64_t)i;
        inverse[i] = modulus - (modulus / value) * inverse[modulus % value] % modulus;
    }
    for (size_t i = 0; i < count; ++i) {
        uint32_t value = (uint32_t)inverse[input[i + 1]];
        output[4 * i] = (uint8_t)value;
        output[4 * i + 1] = (uint8_t)(value >> 8);
        output[4 * i + 2] = (uint8_t)(value >> 16);
        output[4 * i + 3] = (uint8_t)(value >> 24);
    }
    return (int64_t)bytes;
}
