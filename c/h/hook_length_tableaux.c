/* Standard Young-tableau count using the hook-length formula.
 * Independent bounded implementation; see package README for provenance. */
#include <stddef.h>
#include <stdint.h>

#define HOOK_MODULUS INT64_C(998244353)
#define HOOK_MAX_ROWS 65536
#define HOOK_MAX_CELLS 1000000

static int64_t hook_power(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent != 0) {
        if (exponent & 1) result = result * base % HOOK_MODULUS;
        base = base * base % HOOK_MODULUS;
        exponent >>= 1;
    }
    return result;
}

int64_t hook_length_tableaux(const int64_t *input, size_t length) {
    if (!input || length == 0 || input[0] < 0 || input[0] > HOOK_MAX_ROWS)
        return -1;
    size_t rows = (size_t)input[0];
    if (length != rows + 1) return -1;
    int64_t total = 0;
    for (size_t i = 0; i < rows; ++i) {
        int64_t width = input[i + 1];
        if (width < 1 || width > HOOK_MAX_CELLS ||
            (i && width > input[i])) return -1;
        total += width;
        if (total > HOOK_MAX_CELLS) return -1;
    }
    int64_t product = 1;
    if (rows != 0) {
        size_t height = rows;
        for (int64_t column = 0; column < input[1]; ++column) {
            while (height && input[height] <= column) --height;
            for (size_t row = 0; row < height; ++row) {
                int64_t hook = input[row + 1] - column + (int64_t)(height - row - 1);
                product = product * hook % HOOK_MODULUS;
            }
        }
    }
    int64_t factorial = 1;
    for (int64_t i = 2; i <= total; ++i)
        factorial = factorial * i % HOOK_MODULUS;
    return factorial * hook_power(product, HOOK_MODULUS - 2) % HOOK_MODULUS;
}
