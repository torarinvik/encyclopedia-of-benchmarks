#include <stddef.h>
#include <stdint.h>

#define RH_MAX_DEGREE INT64_C(4)
#define RH_MAX_PARSEABLE_LENGTH ((size_t)7)

int64_t routh_hurwitz_stability_predicate(const int64_t *input, size_t length) {
    if (input == NULL || length < 1U || length > RH_MAX_PARSEABLE_LENGTH) return -1;
    const int64_t degree = input[0];
    if (degree < 1 || degree > RH_MAX_DEGREE || length != (size_t)degree + 2U) return -1;

    int64_t coefficients[5] = {0, 0, 0, 0, 0};
    for (int64_t index = 0; index <= degree; ++index) {
        const int64_t value = input[(size_t)index + 1U];
        if (value < -3 || value > 3 || (index == 0 && value <= 0)) return -1;
        coefficients[index] = value;
    }

    const size_t width = (size_t)(degree + 2) / 2U;
    int64_t table[5][3] = {{0}};
    for (size_t column = 0; column < width; ++column) {
        const size_t even_index = 2U * column;
        const size_t odd_index = even_index + 1U;
        if (even_index <= (size_t)degree) table[0][column] = coefficients[even_index];
        if (odd_index <= (size_t)degree) table[1][column] = coefficients[odd_index];
    }

    int row_one_is_zero = 1;
    for (size_t column = 0; column < width; ++column) {
        if (table[1][column] != 0) row_one_is_zero = 0;
    }
    if (row_one_is_zero || table[1][0] <= 0) return 0;

    for (size_t row = 2; row <= (size_t)degree; ++row) {
        if (table[row - 1U][0] <= 0) return 0;
        int all_zero = 1;
        for (size_t column = 0; column < width; ++column) {
            const int64_t upper_next = column + 1U < width ? table[row - 2U][column + 1U] : 0;
            const int64_t lower_next = column + 1U < width ? table[row - 1U][column + 1U] : 0;
            table[row][column] = table[row - 1U][0] * upper_next
                               - table[row - 2U][0] * lower_next;
            if (table[row][column] != 0) all_zero = 0;
        }
        if (all_zero || table[row][0] <= 0) return 0;
    }
    return 1;
}
