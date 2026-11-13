module bareiss_determinant;

const usz MAX_DIMENSION = 8;
const usz MAX_INPUT_LENGTH = 65;
const long INVALID_RESULT = -9223372036854775807L - 1L;

fn long bareiss_determinant(long* input, usz length)
        @export("bareiss_determinant") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    if (input[0] < 1 || input[0] > (long)MAX_DIMENSION) return INVALID_RESULT;
    usz n = (usz)input[0];
    if (length != 1 + n * n) return INVALID_RESULT;

    long[64] matrix = {};
    for (usz index = 0; index < n * n; ++index) {
        long value = input[1 + index];
        if (value < -4 || value > 4) return INVALID_RESULT;
        matrix[index] = value;
    }

    long sign = 1;
    long previous_pivot = 1;
    for (usz k = 0; k + 1 < n; ++k) {
        if (matrix[k * n + k] == 0) {
            usz replacement = k + 1;
            while (replacement < n && matrix[replacement * n + k] == 0) ++replacement;
            if (replacement == n) return 0;
            for (usz column = 0; column < n; ++column) {
                long temporary = matrix[k * n + column];
                matrix[k * n + column] = matrix[replacement * n + column];
                matrix[replacement * n + column] = temporary;
            }
            sign = -sign;
        }

        long pivot = matrix[k * n + k];
        for (usz row = k + 1; row < n; ++row) {
            for (usz column = k + 1; column < n; ++column) {
                long numerator = matrix[row * n + column] * pivot
                    - matrix[row * n + k] * matrix[k * n + column];
                matrix[row * n + column] = numerator / previous_pivot;
            }
            matrix[row * n + k] = 0;
        }
        previous_pivot = pivot;
    }
    return sign * matrix[(n - 1) * n + n - 1];
}
