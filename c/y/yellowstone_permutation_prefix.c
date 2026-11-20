#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MIN_CAP = 3, MAX_CAP = 256, MAX_PARSEABLE_LENGTH = 3 };

static int64_t gcd_positive(int64_t left, int64_t right) {
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static int64_t construct_term(int64_t requested, int64_t candidate_cap) {
    int64_t terms[MAX_N] = {1, 2, 3};
    unsigned char used[MAX_CAP + 1] = {0};
    if (requested <= 3) return terms[(size_t)requested - 1];
    used[1] = used[2] = used[3] = 1;

    size_t term_count = 3;
    while (term_count < (size_t)requested) {
        const int64_t two_back = terms[term_count - 2];
        const int64_t previous = terms[term_count - 1];
        int64_t candidate = 1;
        while (candidate <= candidate_cap) {
            if (used[(size_t)candidate] == 0
                    && gcd_positive(candidate, two_back) > 1
                    && gcd_positive(candidate, previous) == 1) break;
            ++candidate;
        }
        if (candidate > candidate_cap) return -1;
        terms[term_count++] = candidate;
        used[(size_t)candidate] = 1;
    }
    return terms[(size_t)requested - 1];
}

int64_t yellowstone_permutation_prefix(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 2) return -1;
    const int64_t requested = input[0];
    const int64_t candidate_cap = input[1];
    if (requested < 1 || requested > MAX_N
            || candidate_cap < MIN_CAP || candidate_cap > MAX_CAP) return -1;
    return construct_term(requested, candidate_cap);
}
