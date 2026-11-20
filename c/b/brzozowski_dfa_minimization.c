#include <stddef.h>
#include <stdint.h>

enum { MAX_STATES = 3, FIRST_SUBSETS = 1 << MAX_STATES, SECOND_SUBSETS = 1 << FIRST_SUBSETS };

int64_t brzozowski_dfa_minimization(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > 10) return -1;
    const int64_t n64 = input[0], start64 = input[1], accepting64 = input[2];
    if (n64 < 1 || n64 > MAX_STATES || start64 < 0 || start64 >= n64
        || accepting64 < 0 || accepting64 >= (INT64_C(1) << n64)) return -1;
    const size_t n = (size_t)n64;
    if (length != 3 + 2 * n) return -1;
    const size_t start = (size_t)start64;
    const unsigned int accepting = (unsigned int)accepting64;
    size_t transition[MAX_STATES][2] = {{0}};
    for (size_t state = 0; state < n; ++state) {
        for (size_t symbol = 0; symbol < 2; ++symbol) {
            const int64_t target = input[3 + 2 * state + symbol];
            if (target < 0 || target >= n64) return -1;
            transition[state][symbol] = (size_t)target;
        }
    }

    unsigned int first_masks[FIRST_SUBSETS] = {0};
    size_t first_delta[FIRST_SUBSETS][2] = {{0}};
    unsigned char first_final[FIRST_SUBSETS] = {0};
    int first_id[FIRST_SUBSETS];
    for (size_t i = 0; i < FIRST_SUBSETS; ++i) first_id[i] = -1;
    size_t first_count = 1;
    first_masks[0] = accepting;
    first_id[accepting] = 0;
    for (size_t cursor = 0; cursor < first_count; ++cursor) {
        const unsigned int subset = first_masks[cursor];
        first_final[cursor] = (unsigned char)((subset >> start) & 1u);
        for (size_t symbol = 0; symbol < 2; ++symbol) {
            unsigned int predecessor = 0;
            for (size_t state = 0; state < n; ++state)
                if ((subset & (1u << transition[state][symbol])) != 0)
                    predecessor |= 1u << state;
            if (first_id[predecessor] < 0) {
                first_id[predecessor] = (int)first_count;
                first_masks[first_count++] = predecessor;
            }
            first_delta[cursor][symbol] = (size_t)first_id[predecessor];
        }
    }

    unsigned int first_accepting = 0;
    for (size_t state = 0; state < first_count; ++state)
        if (first_final[state]) first_accepting |= 1u << state;

    unsigned int second_queue[SECOND_SUBSETS] = {0};
    unsigned char second_seen[SECOND_SUBSETS] = {0};
    size_t second_count = 1;
    second_queue[0] = first_accepting;
    second_seen[first_accepting] = 1;
    for (size_t cursor = 0; cursor < second_count; ++cursor) {
        const unsigned int subset = second_queue[cursor];
        for (size_t symbol = 0; symbol < 2; ++symbol) {
            unsigned int predecessor = 0;
            for (size_t state = 0; state < first_count; ++state)
                if ((subset & (1u << first_delta[state][symbol])) != 0)
                    predecessor |= 1u << state;
            if (!second_seen[predecessor]) {
                second_seen[predecessor] = 1;
                second_queue[second_count++] = predecessor;
            }
        }
    }
    return (int64_t)second_count;
}
