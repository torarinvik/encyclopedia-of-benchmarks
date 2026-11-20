module lawler_knapsack_profit_scaling_fptas;

const int MAX_N = 8;
const usz MAX_INPUT_LENGTH = 19;
const int MAX_Q = 32;

fn bool ratio_precedes(int left, int right, long* weight, long* profit) {
    long left_product = profit[left] * weight[right];
    long right_product = profit[right] * weight[left];
    return left_product != right_product ? left_product > right_product : left < right;
}

fn long lawler_knapsack_profit_scaling_fptas(long* input, usz length)
        @export("lawler_knapsack_profit_scaling_fptas") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long capacity = input[0], n64 = input[1];
    if (capacity < 1 || capacity > 30 || n64 < 4 || n64 > MAX_N ||
        length != (usz)(2 + 2 * n64)) return -1;
    int n = (int)n64;

    long[MAX_N] weight = zeroed, profit = zeroed;
    int[MAX_N] order = zeroed;
    for (int i = 0; i < n; i += 1) {
        weight[i] = input[2 + 2 * i];
        profit[i] = input[3 + 2 * i];
        if (weight[i] < 1 || weight[i] > capacity || profit[i] < 32 || profit[i] > 200) return -1;
        order[i] = i;
    }
    for (int i = 1; i < n; i += 1) {
        int key = order[i], j = i;
        while (j > 0 && ratio_precedes(key, order[j - 1], &weight[0], &profit[0])) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = key;
    }

    long prefix_profit = 0, room = capacity, prefix_mask = 0;
    bool exact_prefix = true;
    for (int position = 0; position < n; position += 1) {
        int item = order[position];
        if (weight[item] > room) { exact_prefix = false; break; }
        prefix_profit += profit[item];
        prefix_mask |= (long)1 << item;
        room -= weight[item];
        if (room == 0) break;
    }
    if (exact_prefix) return (prefix_profit << 8) | prefix_mask;

    long lower_bound = prefix_profit, maximum_profit = 0;
    for (int i = 0; i < n; i += 1) if (profit[i] > maximum_profit) maximum_profit = profit[i];
    if (maximum_profit > lower_bound) lower_bound = maximum_profit;

    int[MAX_N] small = zeroed, small_count = 0;
    int[33][MAX_N] raw_groups = zeroed;
    int[33] raw_group_count = zeroed;
    for (int i = 0; i < n; i += 1) {
        if (4 * profit[i] <= lower_bound) {
            small[small_count] = i;
            small_count += 1;
            continue;
        }
        int scaled = -1;
        for (int exponent = 0; exponent <= 1; exponent += 1) {
            long scale = (long)1 << exponent;
            if (scale * lower_bound < 4 * profit[i] &&
                4 * profit[i] <= 2 * scale * lower_bound) {
                scaled = (int)(scale * (16 * profit[i] / (scale * lower_bound)));
                break;
            }
        }
        if (scaled < 1 || scaled > MAX_Q || raw_group_count[scaled] >= MAX_N) return -1;
        raw_groups[scaled][raw_group_count[scaled]] = i;
        raw_group_count[scaled] += 1;
    }

    for (int i = 1; i < small_count; i += 1) {
        int key = small[i], j = i;
        while (j > 0 && ratio_precedes(key, small[j - 1], &weight[0], &profit[0])) {
            small[j] = small[j - 1];
            j -= 1;
        }
        small[j] = key;
    }

    int[MAX_N] group_q = zeroed, group_size = zeroed;
    int[MAX_N][MAX_N] group_items = zeroed;
    int group_count = 0;
    for (int q = MAX_Q; q >= 1; q -= 1) {
        int count = raw_group_count[q];
        if (count == 0) continue;
        for (int i = 1; i < count; i += 1) {
            int key = raw_groups[q][i], j = i;
            while (j > 0 &&
                   (weight[key] < weight[raw_groups[q][j - 1]] ||
                    (weight[key] == weight[raw_groups[q][j - 1]] && key < raw_groups[q][j - 1]))) {
                raw_groups[q][j] = raw_groups[q][j - 1];
                j -= 1;
            }
            raw_groups[q][j] = key;
        }
        int keep = 32 / q;
        if (keep > count) keep = count;
        group_q[group_count] = q;
        group_size[group_count] = keep;
        for (int i = 0; i < keep; i += 1) group_items[group_count][i] = raw_groups[q][i];
        group_count += 1;
    }

    long[MAX_Q + 1] dp_weight = zeroed, dp_profit = zeroed, dp_mask = zeroed;
    bool[MAX_Q + 1] dp_valid = zeroed;
    for (int q = 0; q <= MAX_Q; q += 1) dp_weight[q] = capacity + 1;
    dp_weight[0] = 0;
    dp_valid[0] = true;
    for (int group = 0; group < group_count; group += 1) {
        long[MAX_Q + 1] next_weight = zeroed, next_profit = zeroed, next_mask = zeroed;
        bool[MAX_Q + 1] next_valid = zeroed;
        for (int q = 0; q <= MAX_Q; q += 1) next_weight[q] = capacity + 1;
        for (int old_q = 0; old_q <= MAX_Q; old_q += 1) {
            if (!dp_valid[old_q]) continue;
            long added_weight = 0, added_profit = 0, added_mask = 0;
            for (int take = 0; take <= group_size[group]; take += 1) {
                int new_q = old_q + take * group_q[group];
                long candidate_weight = dp_weight[old_q] + added_weight;
                if (new_q <= MAX_Q && candidate_weight <= capacity) {
                    long candidate_profit = dp_profit[old_q] + added_profit;
                    long candidate_mask = dp_mask[old_q] | added_mask;
                    if (!next_valid[new_q] || candidate_weight < next_weight[new_q] ||
                        (candidate_weight == next_weight[new_q] &&
                         (candidate_profit > next_profit[new_q] ||
                          (candidate_profit == next_profit[new_q] && candidate_mask < next_mask[new_q])))) {
                        next_weight[new_q] = candidate_weight;
                        next_profit[new_q] = candidate_profit;
                        next_mask[new_q] = candidate_mask;
                        next_valid[new_q] = true;
                    }
                }
                if (take == group_size[group]) break;
                int item = group_items[group][take];
                added_weight += weight[item];
                if (dp_weight[old_q] + added_weight > capacity) break;
                added_profit += profit[item];
                added_mask |= (long)1 << item;
            }
        }
        long best_weight = capacity + 1;
        for (int q = MAX_Q; q >= 0; q -= 1) {
            if (!next_valid[q]) continue;
            if (next_weight[q] < best_weight) best_weight = next_weight[q];
            else next_valid[q] = false;
        }
        for (int q = 0; q <= MAX_Q; q += 1) {
            dp_weight[q] = next_weight[q];
            dp_profit[q] = next_profit[q];
            dp_mask[q] = next_mask[q];
            dp_valid[q] = next_valid[q];
        }
    }

    long best_score = -1, best_profit = -1, best_weight = capacity + 1, best_mask = 0;
    for (int q = 0; q <= MAX_Q; q += 1) {
        if (!dp_valid[q]) continue;
        long remaining = capacity - dp_weight[q], small_profit = 0, small_weight = 0;
        long mask = dp_mask[q];
        for (int i = 0; i < small_count; i += 1) {
            int item = small[i];
            if (weight[item] > remaining) break;
            remaining -= weight[item];
            small_weight += weight[item];
            small_profit += profit[item];
            mask |= (long)1 << item;
        }
        long total_profit = dp_profit[q] + small_profit;
        long total_weight = dp_weight[q] + small_weight;
        long score = lower_bound * q + 16 * small_profit;
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
    return (best_profit << 8) | best_mask;
}
