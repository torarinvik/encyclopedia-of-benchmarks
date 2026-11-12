/* Finite geometric power sum by binary composition of moment blocks. */
#include <stddef.h>
#include <stdint.h>

#define SEPM_MOD INT64_C(998244353)
#define SEPM_MAX_DEGREE 32

static void sepm_shift(const int64_t *source, uint64_t shift, size_t degree,
                       const int64_t choose[SEPM_MAX_DEGREE + 1][SEPM_MAX_DEGREE + 1],
                       int64_t *destination) {
    int64_t powers[SEPM_MAX_DEGREE + 1] = {0};
    powers[0] = 1;
    const int64_t reduced_shift = (int64_t)(shift % (uint64_t)SEPM_MOD);
    for (size_t i = 1; i <= degree; ++i) powers[i] = powers[i - 1] * reduced_shift % SEPM_MOD;
    for (size_t d = 0; d <= degree; ++d) {
        int64_t total = 0;
        for (size_t k = 0; k <= d; ++k) {
            const int64_t term = choose[d][k] * powers[d - k] % SEPM_MOD;
            total = (total + term * source[k]) % SEPM_MOD;
        }
        destination[d] = total;
    }
}

int64_t sum_of_exponential_times_polynomial(const int64_t *input, size_t length) {
    if (input == NULL || length != 3) return -1;
    const int64_t r = input[0], degree_value = input[1], n_value = input[2];
    if (r < 0 || r >= SEPM_MOD || degree_value < 0 || degree_value > SEPM_MAX_DEGREE ||
        n_value < 0 || n_value > INT64_C(1000000000000000000)) return -1;
    const size_t degree = (size_t)degree_value;
    int64_t choose[SEPM_MAX_DEGREE + 1][SEPM_MAX_DEGREE + 1] = {{0}};
    choose[0][0] = 1;
    for (size_t d = 1; d <= degree; ++d) {
        choose[d][0] = choose[d][d] = 1;
        for (size_t k = 1; k < d; ++k) choose[d][k] = (choose[d - 1][k - 1] + choose[d - 1][k]) % SEPM_MOD;
    }

    int64_t accumulated[SEPM_MAX_DEGREE + 1] = {0};
    int64_t block[SEPM_MAX_DEGREE + 1] = {0};
    int64_t shifted[SEPM_MAX_DEGREE + 1] = {0};
    block[0] = 1;
    int64_t accumulated_power = 1, block_power = r;
    uint64_t accumulated_length = 0, block_length = 1, remaining = (uint64_t)n_value;
    while (remaining > 0) {
        if (remaining & 1U) {
            sepm_shift(block, accumulated_length, degree, choose, shifted);
            for (size_t d = 0; d <= degree; ++d)
                accumulated[d] = (accumulated[d] + accumulated_power * shifted[d]) % SEPM_MOD;
            accumulated_power = accumulated_power * block_power % SEPM_MOD;
            accumulated_length += block_length;
        }
        sepm_shift(block, block_length, degree, choose, shifted);
        for (size_t d = 0; d <= degree; ++d)
            block[d] = (block[d] + block_power * shifted[d]) % SEPM_MOD;
        block_power = block_power * block_power % SEPM_MOD;
        block_length <<= 1;
        remaining >>= 1;
    }
    return accumulated[degree];
}
