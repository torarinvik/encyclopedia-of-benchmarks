#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 14, MAX_CANDIDATE = 64, MAX_SUM = 74, MAX_PARSEABLE_LENGTH = 2 };

int64_t ulam_sequence_1_2(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t requested = input[0];
    if (length != 1 || requested < 1 || requested > MAX_N) return -1;

    int64_t terms[MAX_N] = {0};
    int64_t representations[MAX_SUM + 1] = {0};
    terms[0] = 1;
    terms[1] = 2;
    representations[3] = 1;
    size_t term_count = 2;

    while (term_count < (size_t)requested) {
        int64_t candidate = terms[term_count - 1] + 1;
        while (candidate <= MAX_CANDIDATE && representations[candidate] != 1) ++candidate;
        if (candidate > MAX_CANDIDATE) return -1;
        for (size_t old = 0; old < term_count; ++old) {
            const size_t sum = (size_t)(candidate + terms[old]);
            if (representations[sum] < 2) ++representations[sum];
        }
        terms[term_count++] = candidate;
    }
    return terms[(size_t)requested - 1];
}
