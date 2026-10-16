#include <stddef.h>
#include <stdint.h>

#define MAX_STRING_LENGTH 64
#define MAX_INPUT_LENGTH (3 + 2 * MAX_STRING_LENGTH)

static int64_t fold_ascii(int64_t value, int64_t mode) {
    if (mode == 1 && value >= 'A' && value <= 'Z') return value + ('a' - 'A');
    return value;
}

int64_t comparison(const int64_t *values, size_t length) {
    if (values == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -2;
    const int64_t mode = values[0];
    const int64_t first_length_value = values[1];
    if ((mode != 0 && mode != 1) || first_length_value < 0 || first_length_value > MAX_STRING_LENGTH) return -2;
    const size_t first_length = (size_t)first_length_value;
    const size_t second_length_position = 2 + first_length;
    if (second_length_position >= length) return -2;
    const int64_t second_length_value = values[second_length_position];
    if (second_length_value < 0 || second_length_value > MAX_STRING_LENGTH) return -2;
    const size_t second_length = (size_t)second_length_value;
    const size_t second_start = second_length_position + 1;
    if (second_start + second_length != length) return -2;

    for (size_t index = 0; index < first_length; ++index)
        if (values[2 + index] < 1 || values[2 + index] > 127) return -2;
    for (size_t index = 0; index < second_length; ++index)
        if (values[second_start + index] < 1 || values[second_start + index] > 127) return -2;

    const size_t common_length = first_length < second_length ? first_length : second_length;
    for (size_t index = 0; index < common_length; ++index) {
        const int64_t left = fold_ascii(values[2 + index], mode);
        const int64_t right = fold_ascii(values[second_start + index], mode);
        if (left < right) return -1;
        if (left > right) return 1;
    }
    if (first_length < second_length) return -1;
    if (first_length > second_length) return 1;
    return 0;
}
