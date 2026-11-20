#include <stddef.h>
#include <stdint.h>

#define SCI_MAX_N 12
#define SCI_MAX_INPUT 15
#define SCI_WIDTH (SCI_MAX_N + 1)
#define SCI_INF INT64_C(1000)

static int64_t sci_run_cost(int kept) {
    if (kept == 1) return 1;
    int digits = 0;
    while (kept > 0) { ++digits; kept /= 10; }
    return 1 + digits;
}

int64_t string_compression_ii(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > SCI_MAX_INPUT) return -1;
    int64_t raw_n = input[0], raw_k = input[1];
    if (raw_n < 0 || raw_n > SCI_MAX_N || raw_k < 0 || raw_k > raw_n) return -1;
    size_t n = (size_t)raw_n, budget = (size_t)raw_k;
    if (length != n + 2) return -1;
    for (size_t i = 0; i < n; ++i) if (input[i + 2] < 0 || input[i + 2] > 25) return -1;

    int64_t dp[SCI_WIDTH][SCI_WIDTH];
    for (size_t i = 0; i < SCI_WIDTH; ++i)
        for (size_t d = 0; d < SCI_WIDTH; ++d) dp[i][d] = SCI_INF;
    dp[0][0] = 0;

    for (size_t start = 0; start < n; ++start) {
        for (size_t used = 0; used <= budget; ++used) {
            int64_t prefix_cost = dp[start][used];
            if (prefix_cost == SCI_INF) continue;
            if (used < budget && prefix_cost < dp[start + 1][used + 1])
                dp[start + 1][used + 1] = prefix_cost;

            int same = 0;
            for (size_t end = start; end < n; ++end) {
                if (input[end + 2] == input[start + 2]) ++same;
                int span = (int)(end - start + 1);
                for (int kept = 1; kept <= same; ++kept) {
                    size_t total_deleted = used + (size_t)(span - kept);
                    if (total_deleted > budget) continue;
                    int64_t candidate = prefix_cost + sci_run_cost(kept);
                    if (candidate < dp[end + 1][total_deleted])
                        dp[end + 1][total_deleted] = candidate;
                }
            }
        }
    }

    int64_t answer = SCI_INF;
    for (size_t deleted = 0; deleted <= budget; ++deleted)
        if (dp[n][deleted] < answer) answer = dp[n][deleted];
    return answer;
}
