#include <stddef.h>
#include <stdint.h>

#define SCI_MAX_N 12
#define SCI_WIDTH 16
#define SCI_INF INT64_C(1000)

static int64_t sci_run_cost(int kept) {
    return kept == 1 ? 1 : kept >= 10 ? 3 : 2;
}

int64_t string_compression_ii(const int64_t *input, size_t length) {
    if (input == NULL || length < 2) return -1;
    const uint64_t raw_length = (uint64_t)input[0];
    if (raw_length > SCI_MAX_N || raw_length != length - 2) return -1;
    const uint64_t raw_budget = (uint64_t)input[1];
    if (raw_budget > raw_length) return -1;
    const size_t n = (size_t)raw_length;
    const size_t budget = (size_t)raw_budget;
    if (budget == 0 && n != 0) {
        int64_t previous = input[2];
        if ((uint64_t)previous > 25) return -1;
        int64_t cost = 1;
        int kept = 1;
        for (size_t index = 1; index < n; ++index) {
            const int64_t symbol = input[index + 2];
            if ((uint64_t)symbol > 25) return -1;
            kept = symbol == previous ? kept + 1 : 1;
            /* Run lengths 1, 2, and 10 each add an encoded byte. */
            cost += (UINT64_C(1030) >> kept) & 1;
            previous = symbol;
        }
        return cost;
    }

    if (budget == n) {
        for (size_t index = 0; index < n; ++index)
            if ((uint64_t)input[index + 2] > 25) return -1;
        return 0;
    }
    const int64_t first_symbol = input[2];
    if ((uint64_t)first_symbol > 25) return -1;
    size_t matching = 1;
    for (size_t index = 1; index < n; ++index) {
        const int64_t symbol = input[index + 2];
        if ((uint64_t)symbol > 25) return -1;
        matching += symbol == first_symbol;
    }

    /* A single run attains the minimum possible cost for this retained length. */
    const size_t retained = n - budget;
    if (retained == 1) return 1;
    if (matching >= retained) return sci_run_cost((int)retained);

    /* Store matching endpoints as one-based positions. Zero ends a chain. */
    size_t next_match[SCI_MAX_N];
    size_t latest_match[26] = {0};
    for (size_t position = n; position != 0; --position) {
        const size_t symbol = (size_t)input[position + 1];
        next_match[position - 1] = latest_match[symbol];
        latest_match[symbol] = position;
    }

    int64_t dp[SCI_WIDTH][SCI_WIDTH];
    for (size_t i = 0; i < SCI_WIDTH; ++i)
        for (size_t d = 0; d < SCI_WIDTH; ++d) dp[i][d] = SCI_INF;
    dp[0][0] = 0;

    for (size_t start = 0; start < n; ++start) {
        const size_t remaining = n - start;
        const size_t first_used = budget > remaining ? budget - remaining : 0;
        const size_t last_used = start < budget ? start : budget;
        for (size_t used = first_used; used <= last_used; ++used) {
            int64_t prefix_cost = dp[start][used];
            const size_t kept_limit = retained - (start - used);
            if (used < budget && prefix_cost < dp[start + 1][used + 1])
                dp[start + 1][used + 1] = prefix_cost;

            if (kept_limit == 0) continue;
            size_t endpoint = start + 1;
            for (size_t kept = 1; endpoint != 0; ++kept) {
                const size_t deleted = used + endpoint - start - kept;
                if (deleted > budget) break;
                const int64_t candidate = prefix_cost + sci_run_cost((int)kept);
                if (candidate < dp[endpoint][deleted])
                    dp[endpoint][deleted] = candidate;
                if (kept == kept_limit) break;
                endpoint = next_match[endpoint - 1];
            }
        }
    }
    return dp[n][budget];
}
