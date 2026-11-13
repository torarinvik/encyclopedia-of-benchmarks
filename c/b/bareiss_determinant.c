#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 8
#define MAX_INPUT_LENGTH (1 + MAX_DIMENSION * MAX_DIMENSION)
#define INVALID_RESULT INT64_MIN

int64_t bareiss_determinant(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_DIMENSION) return INVALID_RESULT;
    const int n = (int)n_value;
    if (length != (size_t)(1 + n * n)) return INVALID_RESULT;

    int64_t matrix[MAX_DIMENSION * MAX_DIMENSION] = {0};
    for (int index = 0; index < n * n; ++index) {
        const int64_t value = input[1 + index];
        if (value < -4 || value > 4) return INVALID_RESULT;
        matrix[index] = value;
    }

    int sign = 1;
    int64_t previous_pivot = 1;
    for (int k = 0; k + 1 < n; ++k) {
        if (matrix[k * n + k] == 0) {
            int replacement = k + 1;
            while (replacement < n && matrix[replacement * n + k] == 0) ++replacement;
            if (replacement == n) return 0;
            for (int column = 0; column < n; ++column) {
                const int64_t temporary = matrix[k * n + column];
                matrix[k * n + column] = matrix[replacement * n + column];
                matrix[replacement * n + column] = temporary;
            }
            sign = -sign;
        }

        const int64_t pivot = matrix[k * n + k];
        for (int row = k + 1; row < n; ++row) {
            for (int column = k + 1; column < n; ++column) {
                const int64_t numerator = matrix[row * n + column] * pivot
                    - matrix[row * n + k] * matrix[k * n + column];
                matrix[row * n + column] = numerator / previous_pivot;
            }
            matrix[row * n + k] = 0;
        }
        previous_pivot = pivot;
    }
    return sign * matrix[(n - 1) * n + (n - 1)];
}
