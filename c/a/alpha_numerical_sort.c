/* Compare lowercase ASCII alphanumeric strings in natural order. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_C(-2)
#define MAX_SIDE 64

static int is_digit(int64_t value) { return value >= '0' && value <= '9'; }
static int valid_string(const int64_t *input, size_t start, size_t count)
{
    for (size_t i = 0; i < count; ++i) {
        const int64_t value = input[start + i];
        if (!is_digit(value) && (value < 'a' || value > 'z')) return 0;
        if (value == '0' && i > 0 && is_digit(input[start + i - 1])) return 0;
    }
    return 1;
}

int64_t alpha_numerical_sort(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_SIDE) return INVALID_RESULT;
    const size_t first_length = (size_t)input[0];
    if (first_length + 1 >= length || input[1 + first_length] < 0 || input[1 + first_length] > MAX_SIDE) return INVALID_RESULT;
    const size_t second_length = (size_t)input[1 + first_length];
    if (length != 2 + first_length + second_length) return INVALID_RESULT;
    if (!valid_string(input, 2, first_length) || !valid_string(input, 2 + first_length, second_length)) return INVALID_RESULT;

    size_t i = 0, j = 0;
    while (i < first_length && j < second_length) {
        const int64_t a = input[2 + i], b = input[2 + first_length + j];
        if (is_digit(a) && is_digit(b)) {
            size_t end_a = i, end_b = j;
            while (end_a < first_length && is_digit(input[2 + end_a])) ++end_a;
            while (end_b < second_length && is_digit(input[2 + first_length + end_b])) ++end_b;
            const size_t digits_a = end_a - i, digits_b = end_b - j;
            if (digits_a != digits_b) return digits_a < digits_b ? -1 : 1;
            for (size_t k = 0; k < digits_a; ++k) {
                if (input[2 + i + k] != input[2 + first_length + j + k])
                    return input[2 + i + k] < input[2 + first_length + j + k] ? -1 : 1;
            }
            i = end_a; j = end_b;
        } else {
            if (a != b) return a < b ? -1 : 1;
            ++i; ++j;
        }
    }
    if (i == first_length && j == second_length) return 0;
    return i == first_length ? -1 : 1;
}
