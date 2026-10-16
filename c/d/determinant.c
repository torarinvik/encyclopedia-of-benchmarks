#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 6
#define MAX_INPUT_LENGTH (1 + MAX_DIMENSION * MAX_DIMENSION)
#define INVALID_RESULT INT64_MIN

static int64_t determinant_recursive(const int64_t *matrix, int dimension) {
    if (dimension == 1) return matrix[0];

    int64_t result = 0;
    int64_t minor[(MAX_DIMENSION - 1) * (MAX_DIMENSION - 1)];
    for (int column = 0; column < dimension; ++column) {
        int minor_index = 0;
        for (int row = 1; row < dimension; ++row) {
            for (int source_column = 0; source_column < dimension; ++source_column) {
                if (source_column != column) minor[minor_index++] = matrix[row * dimension + source_column];
            }
        }
        const int64_t term = matrix[column] * determinant_recursive(minor, dimension - 1);
        result += column % 2 == 0 ? term : -term;
    }
    return result;
}

int64_t determinant(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t dimension_value = input[0];
    if (dimension_value < 1 || dimension_value > MAX_DIMENSION) return INVALID_RESULT;
    const int dimension = (int)dimension_value;
    if (length != (size_t)(1 + dimension * dimension)) return INVALID_RESULT;
    for (int index = 0; index < dimension * dimension; ++index) {
        if (input[1 + index] < -9 || input[1 + index] > 9) return INVALID_RESULT;
    }
    return determinant_recursive(input + 1, dimension);
}
