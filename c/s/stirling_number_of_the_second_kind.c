#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16 };
static const int64_t MODULUS = INT64_C(998244353);

int64_t stirling_number_of_the_second_kind(const int64_t *input, size_t length) {
    if (input == NULL || length != 1) return -1;
    const int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;

    int64_t row[MAX_N + 1] = {0};
    row[0] = 1;
    for (size_t current_n = 1; current_n <= n; ++current_n) {
        for (size_t k = current_n; k > 0; --k) {
            row[k] = (row[k - 1] + (int64_t)k * row[k]) % MODULUS;
        }
        row[0] = 0;
    }

    int64_t result = 0;
    for (size_t k = 0; k <= n; ++k) {
        const int64_t weight = (int64_t)(k + 1) * (int64_t)(k + 1) * (int64_t)(k + 1);
        result = (result + weight * row[k]) % MODULUS;
    }
    return result;
}
