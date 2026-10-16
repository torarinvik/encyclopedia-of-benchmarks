#include <stddef.h>
#include <stdint.h>

enum { MAX_DIMENSION = 4, MAX_INPUT_LENGTH = 24 };
static const int64_t MODULUS = INT64_C(1000000007);

static void multiply_matrix(const int64_t *left, const int64_t *right,
                            int64_t *output, size_t dimension)
{
    for (size_t row = 0; row < dimension; ++row) {
        for (size_t column = 0; column < dimension; ++column) {
            int64_t value = 0;
            for (size_t inner = 0; inner < dimension; ++inner) {
                value = (value + (left[row * dimension + inner] % MODULUS) *
                                   (right[inner * dimension + column] % MODULUS) % MODULUS) % MODULUS;
            }
            output[row * dimension + column] = value;
        }
    }
}

int64_t linear_recurrence_matrix(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t dimension_value = input[0];
    const int64_t nth_term = input[1];
    const int64_t constant_or_sum_included = input[2];
    if (dimension_value < 1 || dimension_value > MAX_DIMENSION || nth_term < 0 || nth_term > 1000000 ||
        (constant_or_sum_included != 0 && constant_or_sum_included != 1)) return -1;
    const size_t dimension = (size_t)dimension_value;
    const size_t matrix_count = dimension * dimension;
    if (length != 3 + matrix_count + dimension) return -1;
    if (constant_or_sum_included == 1 && nth_term < dimension_value - 1) return -1;

    int64_t matrix[16] = {0};
    int64_t base_row[4] = {0};
    for (size_t index = 0; index < matrix_count + dimension; ++index) {
        const int64_t value = input[3 + index];
        if (value < 0 || value >= MODULUS) return -1;
        if (index < matrix_count) matrix[index] = value;
        else base_row[index - matrix_count] = value;
    }
    if (nth_term < dimension_value - constant_or_sum_included)
        return base_row[(size_t)(nth_term - constant_or_sum_included)];

    int matrix_is_zero = 1;
    for (size_t index = 0; index < matrix_count; ++index)
        if (matrix[index] != 0) matrix_is_zero = 0;
    if (matrix_is_zero) return 0;

    int64_t result[16] = {0};
    int64_t work[16] = {0};
    for (size_t index = 0; index < dimension; ++index)
        result[index * dimension + index] = 1;
    int64_t power = nth_term - dimension_value + 1 + constant_or_sum_included;
    while (power > 0) {
        if ((power & 1) != 0) {
            multiply_matrix(result, matrix, work, dimension);
            for (size_t index = 0; index < matrix_count; ++index) result[index] = work[index];
        }
        power /= 2;
        multiply_matrix(matrix, matrix, work, dimension);
        for (size_t index = 0; index < matrix_count; ++index) matrix[index] = work[index];
    }

    int64_t value = 0;
    for (size_t index = 0; index < dimension; ++index)
        value = (value + (base_row[index] % MODULUS) *
                         (result[index * dimension + dimension - 1] % MODULUS) % MODULUS) % MODULUS;
    return value;
}
