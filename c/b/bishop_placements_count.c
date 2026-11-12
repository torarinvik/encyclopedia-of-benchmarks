#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_K = 16, MAX_INPUT = 2, MAX_DIAGONALS = 2 * MAX_N };

static int diagonal_size(int index) {
    if ((index & 1) != 0) return (index / 4) * 2 + 1;
    return ((index - 1) / 4) * 2 + 2;
}

static void color_counts(int k, int last_diagonal, int64_t out[MAX_K + 1]) {
    int64_t dp[MAX_DIAGONALS][MAX_K + 1] = {{0}};
    dp[0][0] = 1;
    dp[1][0] = 1;
    if (k >= 1) dp[1][1] = 1;
    for (int diagonal = 2; diagonal <= last_diagonal; ++diagonal) {
        dp[diagonal][0] = 1;
        const int squares = diagonal_size(diagonal);
        for (int placed = 1; placed <= k; ++placed) {
            dp[diagonal][placed] = dp[diagonal - 2][placed] +
                dp[diagonal - 2][placed - 1] * (squares - placed + 1);
        }
    }
    for (int placed = 0; placed <= k; ++placed) out[placed] = dp[last_diagonal][placed];
}

int64_t bishop_placements_count(const int64_t *input, size_t length) {
    if (!input || length != MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_K) return -1;
    const int n = (int)input[0];
    const int k = (int)input[1];
    const int maximum = n == 1 ? 1 : 2 * n - 2;
    if (k > maximum) return 0;
    int64_t total = 0;
    int64_t black_counts[MAX_K + 1] = {0};
    int64_t white_counts[MAX_K + 1] = {0};
    color_counts(k, 2 * n - 1, black_counts);
    color_counts(k, 2 * n - 2, white_counts);
    for (int left = 0; left <= k; ++left) total += black_counts[left] * white_counts[k - left];
    return total;
}
