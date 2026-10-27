#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 6, MAX_INPUT = 73, MAX_OUTPUT_BYTES = 104 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

extern "C" int64_t weak_stable_matching_ties_incomplete(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT) return -1;
    const int64_t n_raw = input[0];
    if (n_raw < 1 || n_raw > MAX_N) return -1;
    const size_t n = (size_t)n_raw;
    const size_t side_size = n * n;
    if (length != 1 + 2 * side_size) return -1;
    int64_t men_rank[MAX_N][MAX_N] = {{0}}, women_rank[MAX_N][MAX_N] = {{0}};
    size_t choices[MAX_N][MAX_N] = {{0}}, choice_count[MAX_N] = {0};
    for (size_t man = 0; man < n; ++man) for (size_t woman = 0; woman < n; ++woman) {
        const int64_t rank = input[1 + man * n + woman];
        if (rank < 0 || rank > n_raw) return -1;
        men_rank[man][woman] = rank;
    }
    for (size_t woman = 0; woman < n; ++woman) for (size_t man = 0; man < n; ++man) {
        const int64_t rank = input[1 + side_size + woman * n + man];
        if (rank < 0 || rank > n_raw || ((rank > 0) != (men_rank[man][woman] > 0))) return -1;
        women_rank[woman][man] = rank;
    }
    for (size_t man = 0; man < n; ++man) for (size_t woman = 0; woman < n; ++woman) {
        if (men_rank[man][woman] == 0) continue;
        size_t at = choice_count[man];
        while (at > 0) {
            const size_t prior = choices[man][at - 1];
            if (men_rank[man][prior] < men_rank[man][woman] ||
                    (men_rank[man][prior] == men_rank[man][woman] && prior < woman)) break;
            choices[man][at] = prior;
            --at;
        }
        choices[man][at] = woman;
        ++choice_count[man];
    }
    int man_partner[MAX_N], woman_partner[MAX_N];
    size_t next_choice[MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) { man_partner[i] = -1; woman_partner[i] = -1; }
    for (;;) {
        int man = -1;
        for (size_t candidate = 0; candidate < n; ++candidate)
            if (man_partner[candidate] < 0 && next_choice[candidate] < choice_count[candidate]) { man = (int)candidate; break; }
        if (man < 0) break;
        const size_t m = (size_t)man, woman = choices[m][next_choice[m]++];
        const int incumbent = woman_partner[woman];
        if (incumbent < 0 || women_rank[woman][m] < women_rank[woman][(size_t)incumbent] ||
                (women_rank[woman][m] == women_rank[woman][(size_t)incumbent] && man < incumbent)) {
            woman_partner[woman] = man;
            man_partner[m] = (int)woman;
            if (incumbent >= 0) man_partner[(size_t)incumbent] = -1;
        }
    }
    int64_t words[1 + 2 * MAX_N] = {0};
    size_t pairs = 0;
    for (size_t man = 0; man < n; ++man) if (man_partner[man] >= 0) {
        words[1 + 2 * pairs] = (int64_t)man;
        words[2 + 2 * pairs] = man_partner[man];
        ++pairs;
    }
    words[0] = (int64_t)pairs;
    const size_t output_bytes = 8 * (1 + 2 * pairs);
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    for (size_t word = 0; word < 1 + 2 * pairs; ++word) store_i64_le(staged, 8 * word, words[word]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
