#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 30, MAX_PARSEABLE_LENGTH = 2, MAX_SUMS = 465 };

int64_t mian_chowla_sequence(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t requested = input[0];
    if (length != 1 || requested < 1 || requested > MAX_N) return -1;

    int64_t terms[MAX_N] = {0};
    int64_t used_sums[MAX_SUMS] = {0};
    size_t term_count = 1;
    size_t sum_count = 1;
    terms[0] = 1;
    used_sums[0] = 2;

    while (term_count < (size_t)requested) {
        int64_t candidate = terms[term_count - 1] + 1;
        for (;;) {
            int valid = 1;
            for (size_t term = 0; term < term_count && valid; ++term) {
                const int64_t sum = candidate + terms[term];
                for (size_t old = 0; old < sum_count; ++old) {
                    if (used_sums[old] == sum) { valid = 0; break; }
                }
            }
            if (valid) {
                const int64_t doubled = 2 * candidate;
                for (size_t old = 0; old < sum_count; ++old) {
                    if (used_sums[old] == doubled) { valid = 0; break; }
                }
            }
            if (valid) break;
            ++candidate;
        }

        for (size_t term = 0; term < term_count; ++term)
            used_sums[sum_count++] = candidate + terms[term];
        used_sums[sum_count++] = 2 * candidate;
        terms[term_count++] = candidate;
    }
    return terms[(size_t)requested - 1];
}
