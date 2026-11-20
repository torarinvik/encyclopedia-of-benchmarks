#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_INPUT_LENGTH = 19, MAX_Q = 32 };

typedef struct {
    int64_t weight;
    int64_t profit;
    uint32_t mask;
    int reachable;
} DpState;

static int ratio_precedes(int left, int right, const int64_t weight[MAX_N],
                          const int64_t profit[MAX_N]) {
    int64_t left_product = profit[left] * weight[right];
    int64_t right_product = profit[right] * weight[left];
    return left_product != right_product ? left_product > right_product : left < right;
}

static void state_consider(DpState *state, int64_t weight, int64_t profit, uint32_t mask) {
    if (!state->reachable || weight < state->weight ||
        (weight == state->weight &&
         (profit > state->profit || (profit == state->profit && mask < state->mask)))) {
        state->weight = weight;
        state->profit = profit;
        state->mask = mask;
        state->reachable = 1;
    }
}

int64_t lawler_knapsack_profit_scaling_fptas(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    int64_t capacity = input[0], n64 = input[1];
    if (capacity < 1 || capacity > 30 || n64 < 4 || n64 > MAX_N ||
        length != 2 + 2 * (size_t)n64) return -1;
    size_t n = (size_t)n64;

    int64_t weight[MAX_N] = {0}, profit[MAX_N] = {0};
    int order[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        weight[i] = input[2 + 2 * i];
        profit[i] = input[3 + 2 * i];
        if (weight[i] < 1 || weight[i] > capacity || profit[i] < 32 || profit[i] > 200) return -1;
        order[i] = (int)i;
    }

    for (size_t i = 1; i < n; ++i) {
        int key = order[i];
        size_t j = i;
        while (j > 0 && ratio_precedes(key, order[j - 1], weight, profit)) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = key;
    }

    int64_t prefix_profit = 0, room = capacity;
    uint32_t prefix_mask = 0;
    int exact_prefix = 1;
    for (size_t position = 0; position < n; ++position) {
        int item = order[position];
        if (weight[item] > room) {
            exact_prefix = 0;
            break;
        }
        prefix_profit += profit[item];
        prefix_mask |= UINT32_C(1) << item;
        room -= weight[item];
        if (room == 0) break;
    }
    if (exact_prefix) return (prefix_profit << 8) | (int64_t)prefix_mask;

    int64_t lower_bound = prefix_profit, maximum_profit = 0;
    for (size_t i = 0; i < n; ++i) if (profit[i] > maximum_profit) maximum_profit = profit[i];
    if (maximum_profit > lower_bound) lower_bound = maximum_profit;

    int small[MAX_N], small_count = 0;
    int raw_groups[33][MAX_N] = {{0}};
    int raw_group_count[33] = {0};
    for (size_t i = 0; i < n; ++i) {
        if (4 * profit[i] <= lower_bound) {
            small[small_count++] = (int)i;
            continue;
        }
        int scaled = -1;
        for (int exponent = 0; exponent <= 1; ++exponent) {
            int64_t scale = INT64_C(1) << exponent;
            if (scale * lower_bound < 4 * profit[i] &&
                4 * profit[i] <= 2 * scale * lower_bound) {
                scaled = (int)(scale * (16 * profit[i] / (scale * lower_bound)));
                break;
            }
        }
        if (scaled < 1 || scaled > MAX_Q || raw_group_count[scaled] >= MAX_N) return -1;
        raw_groups[scaled][raw_group_count[scaled]++] = (int)i;
    }

    for (int i = 1; i < small_count; ++i) {
        int key = small[i];
        int j = i;
        while (j > 0 && ratio_precedes(key, small[j - 1], weight, profit)) {
            small[j] = small[j - 1];
            --j;
        }
        small[j] = key;
    }

    int group_q[MAX_N], group_size[MAX_N], group_items[MAX_N][MAX_N];
    int group_count = 0;
    for (int q = MAX_Q; q >= 1; --q) {
        int count = raw_group_count[q];
        if (count == 0) continue;
        for (int i = 1; i < count; ++i) {
            int key = raw_groups[q][i];
            int j = i;
            while (j > 0 &&
                   (weight[key] < weight[raw_groups[q][j - 1]] ||
                    (weight[key] == weight[raw_groups[q][j - 1]] && key < raw_groups[q][j - 1]))) {
                raw_groups[q][j] = raw_groups[q][j - 1];
                --j;
            }
            raw_groups[q][j] = key;
        }
        int keep = 32 / q;
        if (keep > count) keep = count;
        group_q[group_count] = q;
        group_size[group_count] = keep;
        for (int i = 0; i < keep; ++i) group_items[group_count][i] = raw_groups[q][i];
        ++group_count;
    }

    DpState dp[MAX_Q + 1] = {{0}};
    dp[0].reachable = 1;
    for (int group = 0; group < group_count; ++group) {
        DpState next[MAX_Q + 1] = {{0}};
        int q_value = group_q[group];
        for (int old_q = 0; old_q <= MAX_Q; ++old_q) {
            if (!dp[old_q].reachable) continue;
            int64_t added_weight = 0, added_profit = 0;
            uint32_t added_mask = 0;
            for (int take = 0; take <= group_size[group]; ++take) {
                int new_q = old_q + take * q_value;
                int64_t new_weight = dp[old_q].weight + added_weight;
                if (new_q <= MAX_Q && new_weight <= capacity) {
                    state_consider(&next[new_q], new_weight,
                                   dp[old_q].profit + added_profit,
                                   dp[old_q].mask | added_mask);
                }
                if (take == group_size[group]) break;
                int item = group_items[group][take];
                added_weight += weight[item];
                if (dp[old_q].weight + added_weight > capacity) break;
                added_profit += profit[item];
                added_mask |= UINT32_C(1) << item;
            }
        }
        int64_t best_weight = capacity + 1;
        for (int q = MAX_Q; q >= 0; --q) {
            if (!next[q].reachable) continue;
            if (next[q].weight < best_weight) best_weight = next[q].weight;
            else next[q].reachable = 0;
        }
        for (int q = 0; q <= MAX_Q; ++q) dp[q] = next[q];
    }

    int64_t best_score = -1, best_profit = -1, best_weight = capacity + 1;
    uint32_t best_mask = 0;
    for (int q = 0; q <= MAX_Q; ++q) {
        if (!dp[q].reachable) continue;
        int64_t remaining = capacity - dp[q].weight;
        int64_t small_profit = 0, small_weight = 0;
        uint32_t mask = dp[q].mask;
        for (int i = 0; i < small_count; ++i) {
            int item = small[i];
            if (weight[item] > remaining) break;
            remaining -= weight[item];
            small_weight += weight[item];
            small_profit += profit[item];
            mask |= UINT32_C(1) << item;
        }
        int64_t total_profit = dp[q].profit + small_profit;
        int64_t total_weight = dp[q].weight + small_weight;
        int64_t score = lower_bound * q + 16 * small_profit;
        if (score > best_score ||
            (score == best_score &&
             (total_profit > best_profit ||
              (total_profit == best_profit &&
               (total_weight < best_weight ||
                (total_weight == best_weight && mask < best_mask)))))) {
            best_score = score;
            best_profit = total_profit;
            best_weight = total_weight;
            best_mask = mask;
        }
    }
    return (best_profit << 8) | (int64_t)best_mask;
}
