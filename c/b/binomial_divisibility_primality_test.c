#include <stddef.h>
#include <stdint.h>

#define MAX_N 1000

int64_t binomial_divisibility_primality_test(const int64_t *packed,
                                             size_t length) {
    if (packed == NULL || length != 1) return -1;
    const int64_t n_value = packed[0];
    if (n_value < 2 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;

    int64_t row[MAX_N + 1] = {0};
    row[0] = 1;
    for (size_t degree = 1; degree <= n; ++degree) {
        row[degree] = 1;
        for (size_t index = degree - 1; index > 0; --index)
            row[index] = (row[index] + row[index - 1]) % n_value;
    }
    for (size_t index = 1; index < n; ++index)
        if (row[index] != 0) return 0;
    return 1;
}
