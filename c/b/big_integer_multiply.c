#include <stddef.h>
#include <stdint.h>

int64_t big_integer_multiply(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > 66) return -1;
    const int64_t left_value = input[0], right_value = input[1];
    if (left_value < 1 || left_value > 32 || right_value < 1 || right_value > 32) return -1;
    const size_t left_length = (size_t)left_value, right_length = (size_t)right_value;
    if (length != 2 + left_length + right_length) return -1;
    const int64_t *left = input + 2, *right = left + left_length;
    for (size_t i = 0; i < left_length; ++i)
        if (left[i] < 48 || left[i] > 57) return -1;
    for (size_t i = 0; i < right_length; ++i)
        if (right[i] < 48 || right[i] > 57) return -1;
    if ((left_length > 1 && left[0] == 48) || (right_length > 1 && right[0] == 48)) return -1;

    uint16_t product[64] = {0};
    const size_t product_size = left_length + right_length;
    const int is_zero = (left_length == 1 && left[0] == 48) ||
                        (right_length == 1 && right[0] == 48);
    if (!is_zero) {
        for (size_t i = 0; i < left_length; ++i) {
            for (size_t j = 0; j < right_length; ++j) {
                const size_t position = i + j;
                const uint16_t multiplication = (uint16_t)((left[left_length - i - 1] - 48) *
                                                              (right[right_length - j - 1] - 48));
                product[position + 1] += (product[position] + multiplication) / 10;
                product[position] = (product[position] + multiplication) % 10;
            }
        }
    }
    const size_t effective_size = is_zero ? 1 :
        (product[product_size - 1] == 0 ? product_size - 1 : product_size);
    if (output == NULL || capacity < effective_size) return -2;
    if (is_zero) {
        output[0] = '0';
    } else {
        for (size_t i = 0; i < effective_size; ++i)
            output[i] = (uint8_t)('0' + product[effective_size - i - 1]);
    }
    return (int64_t)effective_size;
}
