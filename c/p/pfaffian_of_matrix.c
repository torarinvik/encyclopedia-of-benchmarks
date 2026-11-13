#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_DIMENSION = 16, MAX_PARSEABLE = 258 };
static const int64_t MODULUS = INT64_C(998244353);

static int64_t normalize(int64_t value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

static int64_t multiply(int64_t left, int64_t right) {
    return (left * right) % MODULUS;
}

static int64_t power(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = multiply(result, base);
        base = multiply(base, base);
        exponent >>= 1;
    }
    return result;
}

int64_t pfaffian_of_matrix(const int64_t *input, size_t length) {
    if (input == NULL || length < 5 || length > MAX_PARSEABLE) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t dimension = (size_t)(2 * input[0]);
    if (length != 1 + dimension * dimension) return -1;

    int64_t matrix[MAX_DIMENSION * MAX_DIMENSION] = {0};
    for (size_t row = 0; row < dimension; ++row) {
        for (size_t column = 0; column < dimension; ++column) {
            const int64_t value = input[1 + row * dimension + column];
            if (value < 0 || value >= MODULUS) return -1;
            matrix[row * MAX_DIMENSION + column] = value;
        }
    }
    for (size_t row = 0; row < dimension; ++row) {
        if (matrix[row * MAX_DIMENSION + row] != 0) return -1;
        for (size_t column = row + 1; column < dimension; ++column) {
            if ((matrix[row * MAX_DIMENSION + column]
                    + matrix[column * MAX_DIMENSION + row]) % MODULUS != 0) return -1;
        }
    }

    int64_t result = 1;
    for (size_t pivot_index = 0; pivot_index < dimension; pivot_index += 2) {
        size_t partner = pivot_index + 1;
        while (partner < dimension
                && matrix[pivot_index * MAX_DIMENSION + partner] == 0) ++partner;
        if (partner == dimension) return 0;
        if (partner != pivot_index + 1) {
            const size_t swapped = pivot_index + 1;
            for (size_t k = 0; k < dimension; ++k) {
                int64_t temporary = matrix[swapped * MAX_DIMENSION + k];
                matrix[swapped * MAX_DIMENSION + k] = matrix[partner * MAX_DIMENSION + k];
                matrix[partner * MAX_DIMENSION + k] = temporary;
            }
            for (size_t k = 0; k < dimension; ++k) {
                int64_t temporary = matrix[k * MAX_DIMENSION + swapped];
                matrix[k * MAX_DIMENSION + swapped] = matrix[k * MAX_DIMENSION + partner];
                matrix[k * MAX_DIMENSION + partner] = temporary;
            }
            result = result == 0 ? 0 : MODULUS - result;
        }

        const size_t first = pivot_index * MAX_DIMENSION;
        const size_t second = (pivot_index + 1) * MAX_DIMENSION;
        const int64_t pivot = matrix[first + pivot_index + 1];
        result = multiply(result, pivot);
        const int64_t inverse = power(pivot, MODULUS - 2);
        for (size_t row = pivot_index + 2; row < dimension; ++row) {
            for (size_t column = row + 1; column < dimension; ++column) {
                int64_t cross = multiply(matrix[first + row], matrix[second + column])
                        - multiply(matrix[first + column], matrix[second + row]);
                cross = normalize(cross);
                const int64_t value = normalize(matrix[row * MAX_DIMENSION + column]
                        - multiply(cross, inverse));
                matrix[row * MAX_DIMENSION + column] = value;
                matrix[column * MAX_DIMENSION + row] = value == 0 ? 0 : MODULUS - value;
            }
        }
    }
    return result;
}
