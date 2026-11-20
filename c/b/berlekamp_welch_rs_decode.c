#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { BW_FIELD = 7, BW_MAX_N = 7, BW_MAX_K = 3, BW_MAX_T = 2, BW_MAX_VARS = 8, BW_MAX_POLY = 5 };

static int bw_mod7(int value)
{
    value %= BW_FIELD;
    return value < 0 ? value + BW_FIELD : value;
}

static int bw_inverse7(int value)
{
    switch (value) {
        case 1: return 1;
        case 2: return 4;
        case 3: return 5;
        case 4: return 2;
        case 5: return 3;
        case 6: return 6;
        default: return 0;
    }
}

static int64_t bw_decode(size_t n, size_t k, size_t errors, const int64_t received[BW_MAX_N])
{
    const size_t q_count = k + errors;
    const size_t e_count = errors + 1;
    const size_t variable_count = q_count + e_count;
    int matrix[BW_MAX_N][BW_MAX_VARS] = {{0}};

    for (size_t row = 0; row < n; ++row) {
        int powers[BW_MAX_POLY] = {1, 0, 0, 0, 0};
        for (size_t degree = 1; degree < BW_MAX_POLY; ++degree)
            powers[degree] = (powers[degree - 1] * (int)row) % BW_FIELD;
        for (size_t degree = 0; degree < q_count; ++degree)
            matrix[row][degree] = powers[degree];
        for (size_t degree = 0; degree < e_count; ++degree)
            matrix[row][q_count + degree] = bw_mod7(-(int)received[row] * powers[degree]);
    }

    size_t pivot_columns[BW_MAX_VARS] = {0};
    uint8_t is_pivot[BW_MAX_VARS] = {0};
    size_t pivot_row = 0;
    for (size_t column = 0; column < variable_count && pivot_row < n; ++column) {
        size_t found = pivot_row;
        while (found < n && matrix[found][column] == 0) ++found;
        if (found == n) continue;
        for (size_t c = 0; c < variable_count; ++c) {
            const int temporary = matrix[pivot_row][c];
            matrix[pivot_row][c] = matrix[found][c];
            matrix[found][c] = temporary;
        }
        const int inverse = bw_inverse7(matrix[pivot_row][column]);
        for (size_t c = 0; c < variable_count; ++c)
            matrix[pivot_row][c] = (matrix[pivot_row][c] * inverse) % BW_FIELD;
        for (size_t row = 0; row < n; ++row) {
            if (row == pivot_row) continue;
            const int factor = matrix[row][column];
            if (factor == 0) continue;
            for (size_t c = 0; c < variable_count; ++c)
                matrix[row][c] = bw_mod7(matrix[row][c] - factor * matrix[pivot_row][c]);
        }
        pivot_columns[pivot_row] = column;
        is_pivot[column] = 1;
        ++pivot_row;
    }

    size_t free_column = variable_count;
    for (size_t column = 0; column < variable_count; ++column) {
        if (!is_pivot[column]) { free_column = column; break; }
    }
    if (free_column == variable_count) return 0;
    int solution[BW_MAX_VARS] = {0};
    solution[free_column] = 1;
    for (size_t row = 0; row < pivot_row; ++row)
        solution[pivot_columns[row]] = bw_mod7(-matrix[row][free_column]);

    int numerator[BW_MAX_POLY] = {0};
    int locator[BW_MAX_POLY] = {0};
    for (size_t degree = 0; degree < q_count; ++degree) numerator[degree] = solution[degree];
    for (size_t degree = 0; degree < e_count; ++degree) locator[degree] = solution[q_count + degree];
    size_t locator_degree = e_count - 1;
    while (locator_degree > 0 && locator[locator_degree] == 0) --locator_degree;
    bool locator_zero = true;
    for (size_t degree = 0; degree < e_count; ++degree)
        if (locator[degree] != 0) locator_zero = false;
    if (locator_zero) return 0;

    int remainder[BW_MAX_POLY] = {0};
    for (size_t degree = 0; degree < q_count; ++degree) remainder[degree] = numerator[degree];
    size_t remainder_degree = q_count - 1;
    while (remainder_degree > 0 && remainder[remainder_degree] == 0) --remainder_degree;
    bool numerator_zero = true;
    for (size_t degree = 0; degree < q_count; ++degree)
        if (remainder[degree] != 0) numerator_zero = false;

    int quotient[BW_MAX_POLY] = {0};
    size_t quotient_count = 1;
    if (!numerator_zero && remainder_degree >= locator_degree)
        quotient_count = remainder_degree - locator_degree + 1;
    const int inverse_lead = bw_inverse7(locator[locator_degree]);
    while (!numerator_zero && remainder_degree >= locator_degree) {
        const size_t shift = remainder_degree - locator_degree;
        const int factor = (remainder[remainder_degree] * inverse_lead) % BW_FIELD;
        quotient[shift] = factor;
        for (size_t degree = 0; degree <= locator_degree; ++degree)
            remainder[shift + degree] = bw_mod7(
                remainder[shift + degree] - factor * locator[degree]);
        while (remainder_degree > 0 && remainder[remainder_degree] == 0) --remainder_degree;
        numerator_zero = true;
        for (size_t degree = 0; degree < q_count; ++degree)
            if (remainder[degree] != 0) numerator_zero = false;
    }
    for (size_t degree = 0; degree < q_count; ++degree)
        if (remainder[degree] != 0) return 0;
    if (quotient_count > k) return 0;

    int coefficients[BW_MAX_K] = {0};
    for (size_t degree = 0; degree < quotient_count; ++degree)
        coefficients[degree] = quotient[degree];
    size_t mismatches = 0;
    for (size_t x = 0; x < n; ++x) {
        int value = 0;
        for (size_t degree = k; degree > 0; --degree)
            value = (value * (int)x + coefficients[degree - 1]) % BW_FIELD;
        if (value != received[x]) ++mismatches;
    }
    if (mismatches > errors) return 0;
    int64_t result = 1;
    int64_t place = 1;
    for (size_t degree = 0; degree < k; ++degree) {
        result += coefficients[degree] * place;
        place *= BW_FIELD;
    }
    return result;
}

int64_t berlekamp_welch_rs_decode(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > 11) return -1;
    const int64_t n_value = input[0];
    const int64_t k_value = input[1];
    const int64_t t_value = input[2];
    if (n_value < 2 || n_value > BW_MAX_N || k_value < 1 || k_value > BW_MAX_K
        || k_value > n_value || t_value < 0 || t_value > BW_MAX_T
        || 2 * t_value > n_value - k_value) return -1;
    const size_t n = (size_t)n_value;
    const size_t k = (size_t)k_value;
    const size_t errors = (size_t)t_value;
    if (length != 3 + n) return -1;
    int64_t received[BW_MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) {
        const int64_t symbol = input[3 + i];
        if (symbol < 0 || symbol >= BW_FIELD) return -1;
        received[i] = symbol;
    }
    return bw_decode(n, k, errors, received);
}
