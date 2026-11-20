#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 8;
constexpr std::size_t kMaxInputLength = 19;
constexpr int kMaxQ = 32;

struct DpState {
    std::int64_t weight = 0;
    std::int64_t profit = 0;
    std::uint32_t mask = 0;
    bool reachable = false;
};

bool ratio_precedes(int left, int right, const std::int64_t* weight,
                    const std::int64_t* profit) noexcept {
    const auto left_product = profit[left] * weight[right];
    const auto right_product = profit[right] * weight[left];
    return left_product != right_product ? left_product > right_product : left < right;
}

void state_consider(DpState& state, std::int64_t weight, std::int64_t profit,
                    std::uint32_t mask) noexcept {
    if (!state.reachable || weight < state.weight ||
        (weight == state.weight &&
         (profit > state.profit || (profit == state.profit && mask < state.mask)))) {
        state.weight = weight;
        state.profit = profit;
        state.mask = mask;
        state.reachable = true;
    }
}
}  // namespace

extern "C" std::int64_t lawler_knapsack_profit_scaling_fptas(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const auto capacity = input[0];
    const auto n64 = input[1];
    if (capacity < 1 || capacity > 30 || n64 < 4 || n64 > static_cast<std::int64_t>(kMaxN) ||
        length != 2 + 2 * static_cast<std::size_t>(n64)) return -1;
    const auto n = static_cast<std::size_t>(n64);

    std::int64_t weight[kMaxN]{}, profit[kMaxN]{};
    int order[kMaxN]{};
    for (std::size_t i = 0; i < n; ++i) {
        weight[i] = input[2 + 2 * i];
        profit[i] = input[3 + 2 * i];
        if (weight[i] < 1 || weight[i] > capacity || profit[i] < 32 || profit[i] > 200) return -1;
        order[i] = static_cast<int>(i);
    }
    for (std::size_t i = 1; i < n; ++i) {
        const int key = order[i];
        auto j = i;
        while (j > 0 && ratio_precedes(key, order[j - 1], weight, profit)) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = key;
    }

    std::int64_t prefix_profit = 0, room = capacity;
    std::uint32_t prefix_mask = 0;
    bool exact_prefix = true;
    for (std::size_t position = 0; position < n; ++position) {
        const int item = order[position];
        if (weight[item] > room) {
            exact_prefix = false;
            break;
        }
        prefix_profit += profit[item];
        prefix_mask |= std::uint32_t{1} << item;
        room -= weight[item];
        if (room == 0) break;
    }
    if (exact_prefix) return (prefix_profit << 8) | static_cast<std::int64_t>(prefix_mask);

    auto lower_bound = prefix_profit;
    std::int64_t maximum_profit = 0;
    for (std::size_t i = 0; i < n; ++i) if (profit[i] > maximum_profit) maximum_profit = profit[i];
    if (maximum_profit > lower_bound) lower_bound = maximum_profit;

    int small[kMaxN]{}, small_count = 0;
    int raw_groups[33][kMaxN]{};
    int raw_group_count[33]{};
    for (std::size_t i = 0; i < n; ++i) {
        if (4 * profit[i] <= lower_bound) {
            small[small_count++] = static_cast<int>(i);
            continue;
        }
        int scaled = -1;
        for (int exponent = 0; exponent <= 1; ++exponent) {
            const std::int64_t scale = std::int64_t{1} << exponent;
            if (scale * lower_bound < 4 * profit[i] &&
                4 * profit[i] <= 2 * scale * lower_bound) {
                scaled = static_cast<int>(scale * (16 * profit[i] / (scale * lower_bound)));
                break;
            }
        }
        if (scaled < 1 || scaled > kMaxQ || raw_group_count[scaled] >= static_cast<int>(kMaxN)) return -1;
        raw_groups[scaled][raw_group_count[scaled]++] = static_cast<int>(i);
    }

    for (int i = 1; i < small_count; ++i) {
        const int key = small[i];
        int j = i;
        while (j > 0 && ratio_precedes(key, small[j - 1], weight, profit)) {
            small[j] = small[j - 1];
            --j;
        }
        small[j] = key;
    }

    int group_q[kMaxN]{}, group_size[kMaxN]{}, group_items[kMaxN][kMaxN]{};
    int group_count = 0;
    for (int q = kMaxQ; q >= 1; --q) {
        const int count = raw_group_count[q];
        if (count == 0) continue;
        for (int i = 1; i < count; ++i) {
            const int key = raw_groups[q][i];
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

    DpState dp[kMaxQ + 1]{};
    dp[0].reachable = true;
    for (int group = 0; group < group_count; ++group) {
        DpState next[kMaxQ + 1]{};
        for (int old_q = 0; old_q <= kMaxQ; ++old_q) {
            if (!dp[old_q].reachable) continue;
            std::int64_t added_weight = 0, added_profit = 0;
            std::uint32_t added_mask = 0;
            for (int take = 0; take <= group_size[group]; ++take) {
                const int new_q = old_q + take * group_q[group];
                const auto new_weight = dp[old_q].weight + added_weight;
                if (new_q <= kMaxQ && new_weight <= capacity) {
                    state_consider(next[new_q], new_weight, dp[old_q].profit + added_profit,
                                   dp[old_q].mask | added_mask);
                }
                if (take == group_size[group]) break;
                const int item = group_items[group][take];
                added_weight += weight[item];
                if (dp[old_q].weight + added_weight > capacity) break;
                added_profit += profit[item];
                added_mask |= std::uint32_t{1} << item;
            }
        }
        std::int64_t best_weight = capacity + 1;
        for (int q = kMaxQ; q >= 0; --q) {
            if (!next[q].reachable) continue;
            if (next[q].weight < best_weight) best_weight = next[q].weight;
            else next[q].reachable = false;
        }
        for (int q = 0; q <= kMaxQ; ++q) dp[q] = next[q];
    }

    std::int64_t best_score = -1, best_profit = -1, best_weight = capacity + 1;
    std::uint32_t best_mask = 0;
    for (int q = 0; q <= kMaxQ; ++q) {
        if (!dp[q].reachable) continue;
        std::int64_t remaining = capacity - dp[q].weight;
        std::int64_t small_profit = 0, small_weight = 0;
        auto mask = dp[q].mask;
        for (int i = 0; i < small_count; ++i) {
            const int item = small[i];
            if (weight[item] > remaining) break;
            remaining -= weight[item];
            small_weight += weight[item];
            small_profit += profit[item];
            mask |= std::uint32_t{1} << item;
        }
        const auto total_profit = dp[q].profit + small_profit;
        const auto total_weight = dp[q].weight + small_weight;
        const auto score = lower_bound * q + 16 * small_profit;
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
    return (best_profit << 8) | static_cast<std::int64_t>(best_mask);
}
