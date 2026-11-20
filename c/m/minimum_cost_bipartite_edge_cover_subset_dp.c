#include <stddef.h>
#include <stdint.h>

enum { MAX_LEFT = 8, MAX_RIGHT = 8, MAX_STATES = 256, MAX_INPUT = 67 };
static const int64_t INF = INT64_C(1) << 60;

int64_t minimum_cost_bipartite_edge_cover_subset_dp(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t left_value = input[0];
    const int64_t right_value = input[1];
    if (left_value < 1 || left_value > MAX_LEFT || right_value < 1 || right_value > MAX_RIGHT)
        return -1;
    const size_t left_count = (size_t)left_value;
    const size_t right_count = (size_t)right_value;
    if (length != 2 + left_count * right_count) return -1;
    for (size_t edge = 0; edge < left_count * right_count; ++edge)
        if (input[2 + edge] < 0 || input[2 + edge] > 1000) return -1;

    const size_t states = (size_t)1 << right_count;
    int64_t current[MAX_STATES];
    int64_t following[MAX_STATES];
    int64_t subset_cost[MAX_STATES];
    for (size_t mask = 0; mask < states; ++mask) current[mask] = INF;
    current[0] = 0;

    for (size_t left = 0; left < left_count; ++left) {
        subset_cost[0] = 0;
        for (size_t subset = 1; subset < states; ++subset) {
            const size_t bit = subset & (~subset + 1);
            size_t right = 0;
            while (((bit >> right) & 1) == 0) ++right;
            subset_cost[subset] = subset_cost[subset ^ bit] + input[2 + left * right_count + right];
        }
        for (size_t mask = 0; mask < states; ++mask) following[mask] = INF;
        for (size_t covered = 0; covered < states; ++covered) {
            if (current[covered] == INF) continue;
            for (size_t selected = 1; selected < states; ++selected) {
                const size_t combined = covered | selected;
                const int64_t candidate = current[covered] + subset_cost[selected];
                if (candidate < following[combined]) following[combined] = candidate;
            }
        }
        for (size_t mask = 0; mask < states; ++mask) current[mask] = following[mask];
    }
    return current[states - 1];
}
