#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 7, MAX_INPUT_WORDS = 52, MAX_OUTPUT_BYTES = 64 };

static void store_i64_le(uint8_t *output, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = (uint8_t)(bits >> (byte * 8));
}

static int64_t residue(int64_t value, int64_t modulus) {
    int64_t result = value % modulus;
    return result < 0 ? result + modulus : result;
}

static int64_t negative_residue(int64_t value, int64_t modulus) {
    return value == 0 ? 0 : modulus - value;
}

int64_t berkowitz_characteristic_polynomial(const int64_t *input, size_t length,
                                             uint8_t *output,
                                             size_t output_capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_WORDS) return -1;
    const int64_t n64 = input[0];
    const int64_t modulus = input[1];
    if (n64 < 1 || n64 > MAX_N || modulus < 2 || modulus > INT64_C(1000000000)) return -1;
    const size_t n = (size_t)n64;
    if (length != 2 + n * n) return -1;

    int64_t matrix[MAX_N * MAX_N] = {0};
    for (size_t i = 0; i < n * n; ++i) {
        const int64_t entry = input[i + 2];
        if (entry < -INT64_C(1000000) || entry > INT64_C(1000000)) return -1;
        matrix[i] = residue(entry, modulus);
    }
    const size_t output_bytes = (n + 1) * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;

    int64_t coefficients[MAX_N + 1] = {0};
    int64_t current[MAX_N + 1] = {0};
    int64_t toeplitz[MAX_N + 1] = {0};
    int64_t vector[MAX_N] = {0};
    int64_t next_vector[MAX_N] = {0};
    coefficients[0] = 1;

    for (size_t size = 1; size <= n; ++size) {
        const size_t start = n - size;
        const size_t block = size - 1;
        for (size_t i = 0; i <= size; ++i) toeplitz[i] = 0;
        toeplitz[0] = 1;
        toeplitz[1] = negative_residue(matrix[start * n + start], modulus);
        for (size_t row = 0; row < block; ++row)
            vector[row] = matrix[(start + 1 + row) * n + start];

        for (size_t power = 0; power < block; ++power) {
            int64_t dot = 0;
            for (size_t col = 0; col < block; ++col)
                dot = (dot + matrix[start * n + start + 1 + col] * vector[col]) % modulus;
            toeplitz[power + 2] = negative_residue(dot, modulus);
            for (size_t row = 0; row < block; ++row) {
                int64_t value = 0;
                for (size_t col = 0; col < block; ++col)
                    value = (value + matrix[(start + 1 + row) * n + start + 1 + col]
                                      * vector[col]) % modulus;
                next_vector[row] = value;
            }
            for (size_t row = 0; row < block; ++row) vector[row] = next_vector[row];
        }

        for (size_t i = 0; i <= size; ++i) {
            int64_t value = 0;
            const size_t last_child = i < size - 1 ? i : size - 1;
            for (size_t j = 0; j <= last_child; ++j)
                value = (value + toeplitz[i - j] * coefficients[j]) % modulus;
            current[i] = value;
        }
        for (size_t i = 0; i <= size; ++i) coefficients[i] = current[i];
    }
    for (size_t i = 0; i <= n; ++i) store_i64_le(output, i, coefficients[i]);
    return (int64_t)output_bytes;
}
