#include <stddef.h>
#include <stdint.h>

#define SCI_MAX_N 12
#define SCI_WIDTH 16
#define SCI_SCORE_BASE UINT32_C(16)

static int64_t sci_run_cost(int kept) {
    return kept == 1 ? 1 : kept >= 10 ? 3 : 2;
}

__attribute__((noinline))
static int64_t sci_keep_four(const int64_t *input, size_t n) {
    uint64_t counts = 0;
    for (size_t index = 0; index < n; ++index) {
        const unsigned shift = 2 * (unsigned)input[index + 2];
        if (((counts >> shift) & 3) == 3) return 2;
        counts += UINT64_C(1) << shift;
    }
    uint64_t triples = counts & (counts >> 1) & UINT64_C(0x5555555555555555);
    /* The fourth symbol must fit before or after the chosen triple. */
    if (input[2] == input[n + 1])
        triples &= ~(UINT64_C(1) << (2 * (unsigned)input[2]));
    return triples != 0 ? 3 : 4;
}

__attribute__((noinline))
static int64_t sci_delete_one(const int64_t *input, size_t n) {
    int64_t cost = 0, saving = 0;
    int64_t older_symbol = -1, previous_symbol = -1;
    size_t older_length = 0, previous_length = 0;
    int64_t next_symbol = input[0];
    for (size_t start = 0; start < n;) {
        const int64_t symbol = next_symbol;
        size_t end = start + 1;
        while (end < n) {
            next_symbol = input[end];
            if (next_symbol != symbol) break;
            ++end;
        }
        const size_t run_length = end - start;
        if (run_length == 1) {
            ++cost;
            if (saving == 0) saving = 1;
        } else {
            /* Each nibble holds the cost in bits 0–1 and deletion saving in bit 2. */
            const uint64_t run = UINT64_C(0x3372222222650) >> (run_length * 4);
            cost += (int64_t)(run & 3);
            const int64_t shrink = (int64_t)((run >> 2) & 1);
            if (shrink > saving) saving = shrink;
        }
        /* Deleting a singleton can join the equal runs on either side. */
        if (older_symbol == symbol) {
            const int64_t crosses_ten = older_length < 10 && run_length < 10
                && older_length + run_length >= 10;
            const int64_t merged_saving = 1 + (older_length > 1) + (run_length > 1) - crosses_ten;
            if (merged_saving > saving) saving = merged_saving;
        }
        older_symbol = run_length == 1 ? previous_symbol : -1;
        older_length = previous_length;
        previous_symbol = symbol;
        previous_length = run_length;
        start = end;
    }
    return cost - saving;
}

__attribute__((noinline))
static int64_t sci_search(const int64_t *input, uint32_t n, uint32_t budget, uint32_t retained);

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
    if (retained <= 2) return (int64_t)retained;
    if (matching >= retained) return sci_run_cost((int)retained);

    if (retained == 4) return sci_keep_four(input, n);
    return sci_search(input, n, budget, retained);
}

__attribute__((noinline))
static int64_t sci_search(const int64_t *input, uint32_t n, uint32_t budget, uint32_t retained) {
    /* With at most two occurrences of each symbol, every kept byte costs one. */
    /* The high bit of each two-bit counter is set after the second occurrence. */
    uint64_t counts = 0;
    uint32_t position = 0;
    for (; position < n; ++position) {
        const unsigned shift = 2 * (unsigned)input[position + 2];
        const uint64_t increment = UINT64_C(1) << shift;
        if (((counts >> shift) & 2) != 0) break;
        counts += increment;
    }
    if (position == n) return (int64_t)retained;
    if (retained == 3) return 2;

    if (budget == 1) return sci_delete_one(input + 2, n);

    uint8_t next_match[SCI_MAX_N + 1];
    next_match[0] = 0;
    uint8_t latest_match[26] = {0};
    for (position = n; position != 0; --position) {
        const uint32_t symbol = (uint32_t)input[position + 1];
        next_match[position] = latest_match[symbol];
        latest_match[symbol] = (uint8_t)position;
    }


    /* Scores are the base minus the encoded cost. Zero marks an unset state. */
    uint32_t dp[SCI_MAX_N + 1][SCI_WIDTH] = {{SCI_SCORE_BASE}};
    uint32_t best_score = SCI_SCORE_BASE - retained;
    for (uint32_t start = 0; start < n; ++start) {
        const uint32_t first_used = (start + 1 > retained ? start + 1 : retained) - retained;
        const uint32_t last_used = start < budget ? start : budget;
        for (uint32_t used = first_used; used <= last_used; ++used) {
            uint32_t prefix_score = dp[start][used];
            const uint32_t kept_limit = retained - (start - used);
            if (kept_limit <= 2) {
                if (prefix_score > best_score + kept_limit) best_score = prefix_score - kept_limit;
                continue;
            }
            /* Any completion with at least three symbols costs at least two bytes. */
            if (prefix_score <= best_score + 2) continue;
            /* The padding column absorbs deletions beyond budget. No later state reads it. */
            if (prefix_score > dp[start + 1][used + 1])
                dp[start + 1][used + 1] = prefix_score;
            const uint32_t singleton_score = prefix_score - 1;
            const uint32_t first_endpoint = start + 1;
            if (singleton_score > dp[first_endpoint][used])
                dp[first_endpoint][used] = singleton_score;
            /* A missing link stays at zero, so only check the budget from length three. */
            const uint32_t second_endpoint = next_match[first_endpoint];
            uint32_t endpoint = next_match[second_endpoint];
            for (uint32_t kept = 3; endpoint != 0; ++kept) {
                const uint32_t deleted = used + endpoint - start - kept;
                if (deleted > budget) break;
                const uint32_t run_cost = kept < 10 ? 2 : 3;
                const uint32_t candidate = prefix_score - run_cost;
                if (kept == kept_limit) {
                    if (candidate > best_score) best_score = candidate;
                    break;
                }
                if (candidate > dp[endpoint][deleted])
                    dp[endpoint][deleted] = candidate;
                endpoint = next_match[endpoint];
            }
        }
    }
    return SCI_SCORE_BASE - best_score;
}
