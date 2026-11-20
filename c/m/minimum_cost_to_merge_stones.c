#include <stddef.h>
#include <stdint.h>

#define MAX_N 30
#define MAX_K 30
#define MAX_PARSEABLE_INPUT_LENGTH 33
#define DP_CELLS (MAX_N * MAX_N * (MAX_K + 1))

static size_t dp_index(size_t left, size_t right, size_t piles) {
    return ((left * MAX_N + right) * (MAX_K + 1)) + piles;
}

int64_t minimum_cost_to_merge_stones(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 2 || input[1] > MAX_K) return -1;
    const size_t n = (size_t)input[0];
    const size_t merge_count = (size_t)input[1];
    if (length != n + 2) return -1;

    int64_t prefix[MAX_N + 1] = {0};
    for (size_t i = 0; i < n; ++i) {
        const int64_t stone = input[i + 2];
        if (stone < 1 || stone > 100) return -1;
        prefix[i + 1] = prefix[i] + stone;
    }
    if ((n - 1) % (merge_count - 1) != 0) return -1;

    const int64_t infinity = INT64_MAX / 4;
    int64_t dp[DP_CELLS];
    for (size_t i = 0; i < DP_CELLS; ++i) dp[i] = infinity;
    for (size_t i = 0; i < n; ++i) dp[dp_index(i, i, 1)] = 0;

    for (size_t interval_length = 2; interval_length <= n; ++interval_length) {
        for (size_t left = 0; left + interval_length <= n; ++left) {
            const size_t right = left + interval_length - 1;
            size_t maximum_piles = merge_count < interval_length ? merge_count : interval_length;
            for (size_t piles = 2; piles <= maximum_piles; ++piles) {
                int64_t best = infinity;
                for (size_t cut = left; cut < right; ++cut) {
                    const int64_t first = dp[dp_index(left, cut, 1)];
                    const int64_t rest = dp[dp_index(cut + 1, right, piles - 1)];
                    if (first < infinity && rest < infinity && first + rest < best)
                        best = first + rest;
                }
                dp[dp_index(left, right, piles)] = best;
            }
            if (interval_length >= merge_count) {
                const int64_t to_k = dp[dp_index(left, right, merge_count)];
                if (to_k < infinity)
                    dp[dp_index(left, right, 1)] = to_k + prefix[right + 1] - prefix[left];
            }
        }
    }
    const int64_t answer = dp[dp_index(0, n - 1, 1)];
    return answer >= infinity ? -1 : answer;
}
