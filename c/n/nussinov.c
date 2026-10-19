#include <stddef.h>
#include <stdint.h>

#define MAX_N 128

int64_t nussinov(const int64_t *values, size_t length) {
    if (values == NULL || length != 1 || values[0] < 1 || values[0] > MAX_N) return -1;
    const size_t n = (size_t)values[0];
    int64_t bases[MAX_N] = {0};
    int64_t table[MAX_N][MAX_N] = {{0}};
    for (size_t i = 0; i < n; ++i) bases[i] = (int64_t)((i + 1) % 4);

    for (size_t i = n; i > 0;) {
        --i;
        for (size_t j = i + 1; j < n; ++j) {
            int64_t score = table[i][j - 1];
            if (i + 1 < n) {
                if (table[i + 1][j] > score) score = table[i + 1][j];
                int64_t inside = table[i + 1][j - 1];
                if (i < j - 1 && bases[i] + bases[j] == 3) ++inside;
                if (inside > score) score = inside;
            }
            for (size_t k = i + 1; k < j; ++k) {
                const int64_t split = table[i][k] + table[k + 1][j];
                if (split > score) score = split;
            }
            table[i][j] = score;
        }
    }

    int64_t checksum = 0;
    for (size_t i = 0; i < n; ++i)
        for (size_t j = i; j < n; ++j)
            checksum += table[i][j];
    return checksum;
}
