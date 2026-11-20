/* Uncompiled duplicate-aware distinct-LCS counting draft. */
#include <stddef.h>
#include <stdint.h>
#define LCS_MOD INT64_C(1000000007)
int64_t count_distinct_lcs(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > 131) return -1;
    int64_t nr = input[0], mr = input[1];
    if (nr < 0 || nr > 64 || mr < 0 || mr > 64 || length != (size_t)(2+nr+mr)) return -1;
    size_t n = (size_t)nr, m = (size_t)mr;
    for (size_t i = 2; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    int previous_length[65] = {0}, current_length[65] = {0};
    int64_t previous_count[65], current_count[65];
    for (size_t j = 0; j <= m; ++j) previous_count[j] = 1;
    for (size_t i = 1; i <= n; ++i) {
        current_length[0] = 0; current_count[0] = 1;
        for (size_t j = 1; j <= m; ++j) {
            if (input[1+i] == input[1+n+j]) {
                current_length[j] = previous_length[j-1]+1;
                current_count[j] = previous_count[j-1];
            } else {
                int best = previous_length[j] > current_length[j-1] ? previous_length[j] : current_length[j-1];
                int64_t count = 0;
                if (previous_length[j] == best) count += previous_count[j];
                if (current_length[j-1] == best) count += current_count[j-1];
                if (previous_length[j-1] == best) count -= previous_count[j-1];
                current_length[j] = best;
                current_count[j] = (count + LCS_MOD) % LCS_MOD;
            }
        }
        for (size_t j = 0; j <= m; ++j) {
            previous_length[j] = current_length[j]; previous_count[j] = current_count[j];
        }
    }
    return previous_count[m];
}
