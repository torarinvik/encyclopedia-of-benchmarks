#include <stddef.h>
#include <stdint.h>

enum { MAX_T = 8, MAX_K = 8, WIDTH = 9 };
static const int64_t MAX_N = INT64_C(1000000000000000000);

static int is_prime(int64_t value) {
    if (value < 2) return 0;
    for (int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

static int64_t stirling_value(int64_t n, size_t k, int64_t modulus) {
    int64_t matrix[WIDTH * WIDTH] = {0};
    int64_t squared[WIDTH * WIDTH] = {0};
    int64_t vector[WIDTH] = {0};
    int64_t next_vector[WIDTH] = {0};
    const size_t dimension = k + 1;
    for (size_t index = 0; index < dimension; ++index) {
        matrix[index * WIDTH + index] = (int64_t)index % modulus;
        if (index > 0) matrix[index * WIDTH + index - 1] = 1;
    }
    vector[0] = 1;

    int64_t exponent = n;
    while (exponent > 0) {
        if (exponent % 2 != 0) {
            for (size_t row = 0; row < dimension; ++row) {
                int64_t total = 0;
                for (size_t column = 0; column < dimension; ++column) {
                    total = (total + matrix[row * WIDTH + column] * vector[column]) % modulus;
                }
                next_vector[row] = total;
            }
            for (size_t row = 0; row < dimension; ++row) vector[row] = next_vector[row];
        }
        exponent /= 2;
        if (exponent > 0) {
            for (size_t row = 0; row < dimension; ++row) {
                for (size_t column = 0; column < dimension; ++column) {
                    int64_t total = 0;
                    for (size_t inner = 0; inner < dimension; ++inner) {
                        total = (total + matrix[row * WIDTH + inner] * matrix[inner * WIDTH + column]) % modulus;
                    }
                    squared[row * WIDTH + column] = total;
                }
            }
            for (size_t row = 0; row < dimension; ++row) {
                for (size_t column = 0; column < dimension; ++column) {
                    matrix[row * WIDTH + column] = squared[row * WIDTH + column];
                    squared[row * WIDTH + column] = 0;
                }
            }
        }
    }
    return vector[k];
}

int64_t stirling_number_of_the_second_kind_small_p_large_n(
    const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > 2 + 2 * MAX_T) return -1;
    const int64_t count_value = input[0];
    const int64_t modulus = input[1];
    if (count_value < 1 || count_value > MAX_T
            || length != (size_t)(2 + 2 * count_value)
            || modulus < 11 || modulus > 97 || !is_prime(modulus)) return -1;

    int64_t result = 0;
    for (size_t case_index = 0; case_index < (size_t)count_value; ++case_index) {
        const int64_t n = input[2 + 2 * case_index];
        const int64_t k_value = input[3 + 2 * case_index];
        if (n < 0 || n > MAX_N || k_value < 0 || k_value > MAX_K || k_value > n) return -1;
        const size_t k = (size_t)k_value;
        const int64_t value = stirling_value(n, k, modulus);
        const int64_t weight = (int64_t)(case_index + 1) * (int64_t)(case_index + 1);
        result = (result + weight * value) % modulus;
    }
    return result;
}
