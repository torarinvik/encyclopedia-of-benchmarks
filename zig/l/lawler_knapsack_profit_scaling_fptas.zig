const MAX_N: usize = 8;
const MAX_INPUT: usize = 19;
const MAX_GROUP_Q: usize = 16;
const MAX_Q: usize = 32;

pub export fn lawler_knapsack_profit_scaling_fptas(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const capacity = input[0];
    const n64 = input[1];
    if (capacity < 1 or capacity > 30 or n64 < 4 or n64 > @as(i64, @intCast(MAX_N))
        or length != 2 + 2 * @as(usize, @intCast(n64))) return -1;
    const n: usize = @intCast(n64);

    var weights: [MAX_N]i64 = [_]i64{0} ** MAX_N;
    var profits: [MAX_N]i64 = [_]i64{0} ** MAX_N;
    var order: [MAX_N]usize = [_]usize{0} ** MAX_N;
    var maximum_profit: i64 = 0;
    for (0..n) |i| {
        weights[i] = input[2 + 2 * i];
        profits[i] = input[3 + 2 * i];
        if (weights[i] < 1 or weights[i] > capacity or profits[i] < 32 or profits[i] > 200) return -1;
        order[i] = i;
        maximum_profit = @max(maximum_profit, profits[i]);
    }

    // Stable insertion sort by exact descending profit/weight ratio.
    for (1..n) |i| {
        const key = order[i];
        var j = i;
        while (j > 0 and profits[key] * weights[order[j - 1]] > profits[order[j - 1]] * weights[key]) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = key;
    }

    var prefix_mask: i64 = 0;
    var prefix_profit: i64 = 0;
    var used: i64 = 0;
    var lower_bound: i64 = 0;
    var exact = false;
    for (0..n) |position| {
        const item = order[position];
        if (used + weights[item] > capacity) {
            lower_bound = @max(prefix_profit, maximum_profit);
            break;
        }
        used += weights[item];
        prefix_profit += profits[item];
        prefix_mask |= @as(i64, 1) << @intCast(item);
        if (used == capacity or position + 1 == n) {
            exact = true;
            break;
        }
    }
    if (exact) return (prefix_profit << 8) | prefix_mask;

    var small_order: [MAX_N]usize = [_]usize{0} ** MAX_N;
    var small_count: usize = 0;
    var group_count: [MAX_GROUP_Q + 1]usize = [_]usize{0} ** (MAX_GROUP_Q + 1);
    var group_items: [17 * MAX_N]usize = [_]usize{0} ** (17 * MAX_N);
    for (0..n) |i| {
        if (4 * profits[i] <= lower_bound) {
            small_order[small_count] = i;
            small_count += 1;
        } else {
            var q: usize = 0;
            if (4 * profits[i] <= 2 * lower_bound) {
                q = @intCast(@divTrunc(16 * profits[i], lower_bound));
            } else {
                q = @intCast(2 * @divTrunc(8 * profits[i], lower_bound));
            }
            if (q < 1 or q > MAX_GROUP_Q) return -1;
            group_items[q * n + group_count[q]] = i;
            group_count[q] += 1;
        }
    }

    for (1..small_count) |i| {
        const key = small_order[i];
        var j = i;
        while (j > 0 and profits[key] * weights[small_order[j - 1]] > profits[small_order[j - 1]] * weights[key]) {
            small_order[j] = small_order[j - 1];
            j -= 1;
        }
        small_order[j] = key;
    }
    for (1..MAX_GROUP_Q + 1) |q| {
        const base = q * n;
        for (1..group_count[q]) |i| {
            const key = group_items[base + i];
            var j = i;
            while (j > 0) {
                const previous = group_items[base + j - 1];
                if (weights[key] > weights[previous] or (weights[key] == weights[previous] and key > previous)) break;
                group_items[base + j] = previous;
                j -= 1;
            }
            group_items[base + j] = key;
        }
        const limit = 32 / q;
        if (group_count[q] > limit) group_count[q] = limit;
    }

    // Keep the lightest state for each scaled large-profit total.
    var state_weight: [MAX_Q + 1]i64 = [_]i64{capacity + 1} ** (MAX_Q + 1);
    var state_mask: [MAX_Q + 1]i64 = [_]i64{0} ** (MAX_Q + 1);
    var state_profit: [MAX_Q + 1]i64 = [_]i64{0} ** (MAX_Q + 1);
    state_weight[0] = 0;

    var group_step: usize = 0;
    while (group_step < 16) : (group_step += 1) {
        const q = 16 - group_step;
        const count = group_count[q];
        if (count == 0) continue;

        var next_weight: [MAX_Q + 1]i64 = [_]i64{capacity + 1} ** (MAX_Q + 1);
        var next_mask: [MAX_Q + 1]i64 = [_]i64{0} ** (MAX_Q + 1);
        var next_profit: [MAX_Q + 1]i64 = [_]i64{0} ** (MAX_Q + 1);
        for (0..MAX_Q + 1) |old_q| {
            if (state_weight[old_q] > capacity) continue;
            if (state_weight[old_q] < next_weight[old_q]
                or (state_weight[old_q] == next_weight[old_q]
                    and (state_profit[old_q] > next_profit[old_q]
                        or (state_profit[old_q] == next_profit[old_q]
                            and state_mask[old_q] < next_mask[old_q])))) {
                next_weight[old_q] = state_weight[old_q];
                next_mask[old_q] = state_mask[old_q];
                next_profit[old_q] = state_profit[old_q];
            }
            var group_weight: i64 = 0;
            var group_mask: i64 = 0;
            var group_profit: i64 = 0;
            for (0..count) |offset| {
                const item = group_items[q * n + offset];
                const new_group_weight = group_weight + weights[item];
                if (state_weight[old_q] + new_group_weight > capacity) break;
                group_weight = new_group_weight;
                group_mask |= @as(i64, 1) << @intCast(item);
                group_profit += profits[item];
                const destination = old_q + q * (offset + 1);
                if (destination > MAX_Q) continue;
                const new_weight = state_weight[old_q] + group_weight;
                const new_profit = state_profit[old_q] + group_profit;
                const new_mask = state_mask[old_q] | group_mask;
                if (new_weight < next_weight[destination]
                    or (new_weight == next_weight[destination]
                        and (new_profit > next_profit[destination]
                            or (new_profit == next_profit[destination]
                                and new_mask < next_mask[destination])))) {
                    next_weight[destination] = new_weight;
                    next_mask[destination] = new_mask;
                    next_profit[destination] = new_profit;
                }
            }
        }
        var best_higher_weight = capacity + 1;
        var step: usize = 0;
        while (step < MAX_Q + 1) : (step += 1) {
            const scaled = MAX_Q - step;
            if (next_weight[scaled] <= capacity and next_weight[scaled] < best_higher_weight) {
                best_higher_weight = next_weight[scaled];
            } else {
                next_weight[scaled] = capacity + 1;
                next_mask[scaled] = 0;
                next_profit[scaled] = 0;
            }
        }
        state_weight = next_weight;
        state_mask = next_mask;
        state_profit = next_profit;
    }

    var best_score: i64 = -1;
    var best_profit: i64 = -1;
    var best_weight = capacity + 1;
    var best_mask: i64 = 0;
    for (0..MAX_Q + 1) |scaled| {
        if (state_weight[scaled] > capacity) continue;
        var remaining = capacity - state_weight[scaled];
        var small_mask: i64 = 0;
        var small_profit: i64 = 0;
        var small_weight: i64 = 0;
        for (0..small_count) |position| {
            const item = small_order[position];
            if (weights[item] > remaining) break;
            remaining -= weights[item];
            small_weight += weights[item];
            small_profit += profits[item];
            small_mask |= @as(i64, 1) << @intCast(item);
        }
        const score = lower_bound * @as(i64, @intCast(scaled)) + 16 * small_profit;
        const total_profit = state_profit[scaled] + small_profit;
        const total_weight = state_weight[scaled] + small_weight;
        const mask = state_mask[scaled] | small_mask;
        if (score > best_score or (score == best_score
            and (total_profit > best_profit or (total_profit == best_profit
                and (total_weight < best_weight or (total_weight == best_weight and mask < best_mask))))) ) {
            best_score = score;
            best_profit = total_profit;
            best_weight = total_weight;
            best_mask = mask;
        }
    }
    return (best_profit << 8) | best_mask;
}
