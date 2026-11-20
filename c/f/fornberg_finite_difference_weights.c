#include <stddef.h>
#include <stdint.h>

#define MODULUS INT64_C(998244353)
#define MAX_NODES 8
#define MAX_DERIVATIVE 3
#define MAX_INPUT_LENGTH 12

static int64_t mod_pow(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

static int64_t mod_norm(int64_t value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t fornberg_finite_difference_weights(const int64_t *input, size_t length,
                                            uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    const int64_t order_value = input[1];
    if (n_value < 1 || n_value > MAX_NODES || order_value < 0 || order_value > MAX_DERIVATIVE
        || order_value >= n_value || length != (size_t)n_value + 3) return -1;
    const size_t n = (size_t)n_value;
    const int64_t target = input[2];
    if (target < 0 || target >= MODULUS) return -1;
    for (size_t i = 0; i < n; ++i) {
        const int64_t node = input[3 + i];
        if (node < 0 || node >= MODULUS) return -1;
        for (size_t j = 0; j < i; ++j)
            if (node == input[3 + j]) return -1;
    }

    int64_t table[MAX_NODES][MAX_DERIVATIVE + 1] = {{0}};
    table[0][0] = 1;
    int64_t previous_product = 1;
    for (size_t new_index = 1; new_index < n; ++new_index) {
        int64_t old_last[MAX_DERIVATIVE + 1];
        for (size_t d = 0; d <= MAX_DERIVATIVE; ++d)
            old_last[d] = table[new_index - 1][d];
        int64_t product = 1;
        const int64_t node = input[3 + new_index];
        const int64_t factor = mod_norm(node - target);
        const int max_d = new_index < (size_t)order_value ? (int)new_index : (int)order_value;
        for (size_t old_index = 0; old_index < new_index; ++old_index) {
            const int64_t difference = mod_norm(node - input[3 + old_index]);
            product = product * difference % MODULUS;
            const int64_t inverse_difference = mod_pow(difference, MODULUS - 2);
            for (int d = max_d; d >= 0; --d) {
                const int64_t lower = d == 0 ? 0 : table[old_index][d - 1];
                const int64_t numerator = mod_norm(factor * table[old_index][d] - d * lower);
                table[old_index][d] = numerator * inverse_difference % MODULUS;
            }
        }
        const int64_t product_inverse = mod_pow(product, MODULUS - 2);
        const int64_t last_factor = mod_norm(input[2 + new_index] - target);
        for (int d = 0; d <= max_d; ++d) {
            const int64_t lower = d == 0 ? 0 : old_last[d - 1];
            const int64_t numerator = mod_norm(d * lower - last_factor * old_last[d]);
            table[new_index][d] = previous_product * product_inverse % MODULUS * numerator % MODULUS;
        }
        previous_product = product;
    }

    const size_t required = 8 * (n + 1);
    if (output == NULL || capacity < required) return -2;
    store_i64_le(output, 0, n_value);
    for (size_t i = 0; i < n; ++i)
        store_i64_le(output, 8 * (i + 1), table[i][(size_t)order_value]);
    return (int64_t)required;
}
