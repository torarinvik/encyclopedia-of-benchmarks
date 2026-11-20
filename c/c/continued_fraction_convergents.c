#include <stddef.h>
#include <stdint.h>

#define MAX_COEFFICIENTS 16
#define MAX_INPUT_LENGTH 18

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t continued_fraction_convergents(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = input[0];
    if (count_value < 1 || count_value > MAX_COEFFICIENTS) return -1;
    const size_t count = (size_t)count_value;
    if (length != count + 1 || input[1] < -1000 || input[1] > 1000) return -1;
    for (size_t i = 2; i < length; ++i)
        if (input[i] < 1 || input[i] > 8) return -1;

    const size_t required = 16 * count;
    if (output == NULL || capacity < required) return -2;

    int64_t p_two_back = 0, p_one_back = 1;
    int64_t q_two_back = 1, q_one_back = 0;
    for (size_t i = 0; i < count; ++i) {
        const int64_t p = input[i + 1] * p_one_back + p_two_back;
        const int64_t q = input[i + 1] * q_one_back + q_two_back;
        store_i64_le(output, 16 * i, p);
        store_i64_le(output, 16 * i + 8, q);
        p_two_back = p_one_back; p_one_back = p;
        q_two_back = q_one_back; q_one_back = q;
    }
    return (int64_t)required;
}
