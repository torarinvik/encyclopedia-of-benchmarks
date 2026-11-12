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
    const int64_t quotient = n / modulus;
    const int64_t remainder = n % modulus;
    if (quotient > (int64_t)k) return 0;
    const size_t target = k - (size_t)quotient;
    int64_t coefficients[WIDTH] = {0};
    coefficients[0] = 1;
    for (int64_t residue = 0; residue < remainder; ++residue) {
        for (size_t degree = target; degree > 0; --degree) {
            coefficients[degree] = (coefficients[degree - 1] - residue * coefficients[degree]) % modulus;
            if (coefficients[degree] < 0) coefficients[degree] += modulus;
        }
        coefficients[0] = (-residue * coefficients[0]) % modulus;
        if (coefficients[0] < 0) coefficients[0] += modulus;
    }
    const int64_t coefficient = coefficients[target];
    return quotient % 2 == 0 || coefficient == 0 ? coefficient : modulus - coefficient;
}

int64_t stirling_number_of_the_first_kind_small_p_large_n(
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
        const int64_t value = stirling_value(n, (size_t)k_value, modulus);
        const int64_t next = (int64_t)(case_index + 1);
        result = (result + next * next * value) % modulus;
    }
    return result;
}
