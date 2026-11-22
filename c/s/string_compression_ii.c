#include <stddef.h>
#include <stdint.h>

#define SCI_MAX_N 12
#define SCI_MAX_INPUT 15
#define SCI_WIDTH 16
#define SCI_INF INT64_C(1000)

static int64_t sci_run_cost(int kept) {
    return kept == 1 ? 1 : kept >= 10 ? 3 : 2;
}

int64_t string_compression_ii(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > SCI_MAX_INPUT) return -1;
    int64_t raw_n = input[0], raw_k = input[1];
    if (raw_n < 0 || raw_n > SCI_MAX_N || raw_k < 0 || raw_k > raw_n) return -1;
    size_t n = (size_t)raw_n, budget = (size_t)raw_k;
    if (length != n + 2) return -1;
    if (budget == 0 && n != 0) {
        int64_t previous = input[2];
        if ((uint64_t)previous > 25) return -1;
        int64_t cost = 0;
        int kept = 1;
        for (size_t index = 1; index < n; ++index) {
            const int64_t symbol = input[index + 2];
            if ((uint64_t)symbol > 25) return -1;
            if (symbol == previous) {
                ++kept;
            } else {
                cost += sci_run_cost(kept);
                kept = 1;
            }
            previous = symbol;
        }
        return cost + sci_run_cost(kept);
    }

    for (size_t index = 0; index < n; ++index)
        if ((uint64_t)input[index + 2] > 25) return -1;
    if (budget == n) return 0;

    /* A single run attains the minimum possible cost for this retained length. */
    const size_t retained = n - budget;
    if (retained == 1) return 1;
    const int64_t first_symbol = input[2];
    size_t needed = retained - 1;
    for (size_t index = 1; index < n; ++index) {
        if (input[index + 2] == first_symbol && --needed == 0)
            return sci_run_cost((int)retained);
    }

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

            const int64_t symbol = input[start + 2];
            int kept = 0;
            size_t deleted = used;
            for (size_t end = start; end < n; ++end) {
                if (input[end + 2] != symbol) {
                    if (++deleted > budget) break;
                    continue;
                }
                const int64_t candidate = prefix_cost + sci_run_cost(++kept);
                if (candidate < dp[end + 1][deleted])
                    dp[end + 1][deleted] = candidate;
            }
        }
    }

    int64_t answer = SCI_INF;
    for (size_t deleted = 0; deleted <= budget; ++deleted)
        if (dp[n][deleted] < answer) answer = dp[n][deleted];
    return answer;
}
