from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("lawler_knapsack_profit_scaling_fptas")
fn lawler_knapsack_profit_scaling_fptas(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 19:
        return -1
    let capacity = input[0]
    let n0 = input[1]
    if capacity < 1 or capacity > 30 or n0 < 4 or n0 > 8:
        return -1
    let n = Int(n0)
    if length != c_size_t(2 + 2 * n0):
        return -1

    var weights = List[Int64](length=n, fill=0)
    var profits = List[Int64](length=n, fill=0)
    var ratio_order = List[Int](length=n, fill=0)
    var maximum_profit: Int64 = 0
    for i in range(n):
        weights[i] = input[2 + 2 * i]
        profits[i] = input[3 + 2 * i]
        if weights[i] < 1 or weights[i] > capacity or profits[i] < 32 or profits[i] > 200:
            return -1
        ratio_order[i] = i
        if profits[i] > maximum_profit:
            maximum_profit = profits[i]

    # Stable exact-ratio insertion sort: equal ratios keep input order.
    for i in range(1, n):
        let key = ratio_order[i]
        var j = i
        while j > 0 and profits[key] * weights[ratio_order[j - 1]] > profits[ratio_order[j - 1]] * weights[key]:
            ratio_order[j] = ratio_order[j - 1]
            j -= 1
        ratio_order[j] = key

    var prefix_mask: Int64 = 0
    var prefix_profit: Int64 = 0
    var used: Int64 = 0
    var lower_bound: Int64 = 0
    var exact = False
    for position in range(n):
        let item = ratio_order[position]
        if used + weights[item] > capacity:
            lower_bound = prefix_profit
            if maximum_profit > lower_bound:
                lower_bound = maximum_profit
            break
        used += weights[item]
        prefix_profit += profits[item]
        prefix_mask |= Int64(1) << item
        if used == capacity or position + 1 == n:
            exact = True
            break
    if exact:
        return (prefix_profit << 8) | prefix_mask

    var small_order = List[Int](length=n, fill=0)
    var small_count = 0
    var group_count = List[Int](length=17, fill=0)
    var group_items = List[Int](length=17 * n, fill=0)

    for i in range(n):
        if 4 * profits[i] <= lower_bound:
            small_order[small_count] = i
            small_count += 1
        else:
            var q = 0
            if 4 * profits[i] <= 2 * lower_bound:
                q = Int(16 * profits[i] // lower_bound)
            else:
                q = 2 * Int(8 * profits[i] // lower_bound)
            if q < 1 or q > 16:
                return -1
            let slot = q * n + group_count[q]
            group_items[slot] = i
            group_count[q] += 1

    # Small items use the same exact ratio ordering and index tie as the bound.
    for i in range(1, small_count):
        let key = small_order[i]
        var j = i
        while j > 0 and profits[key] * weights[small_order[j - 1]] > profits[small_order[j - 1]] * weights[key]:
            small_order[j] = small_order[j - 1]
            j -= 1
        small_order[j] = key

    # Keep only floor(32/q) lightest candidates in each equal-q group.
    for q in range(1, 17):
        let base = q * n
        for i in range(1, group_count[q]):
            let key = group_items[base + i]
            var j = i
            while j > 0:
                let previous = group_items[base + j - 1]
                if weights[key] > weights[previous] or (weights[key] == weights[previous] and key > previous):
                    break
                group_items[base + j] = previous
                j -= 1
            group_items[base + j] = key
        let limit = 32 // q
        if group_count[q] > limit:
            group_count[q] = limit

    # A q-indexed frontier stores the lightest state for each scaled total.
    var state_weight = List[Int64](length=33, fill=capacity + 1)
    var state_mask = List[Int64](length=33, fill=0)
    var state_profit = List[Int64](length=33, fill=0)
    state_weight[0] = 0

    for group_step in range(16):
        let q = 16 - group_step
        let count = group_count[q]
        if count == 0:
            continue

        var next_weight = List[Int64](length=33, fill=capacity + 1)
        var next_mask = List[Int64](length=33, fill=0)
        var next_profit = List[Int64](length=33, fill=0)
        for old_q in range(33):
            if state_weight[old_q] > capacity:
                continue
            if state_weight[old_q] < next_weight[old_q] or (state_weight[old_q] == next_weight[old_q] and (state_profit[old_q] > next_profit[old_q] or (state_profit[old_q] == next_profit[old_q] and state_mask[old_q] < next_mask[old_q]))):
                next_weight[old_q] = state_weight[old_q]
                next_mask[old_q] = state_mask[old_q]
                next_profit[old_q] = state_profit[old_q]
            var group_weight: Int64 = 0
            var group_mask: Int64 = 0
            var group_profit: Int64 = 0
            for offset in range(count):
                let item = group_items[q * n + offset]
                let new_group_weight = group_weight + weights[item]
                if state_weight[old_q] + new_group_weight > capacity:
                    break
                group_weight = new_group_weight
                group_mask |= Int64(1) << item
                group_profit += profits[item]
                let destination = old_q + q * (offset + 1)
                if destination > 32:
                    continue
                let new_weight = state_weight[old_q] + group_weight
                let new_profit = state_profit[old_q] + group_profit
                let new_mask = state_mask[old_q] | group_mask
                if new_weight < next_weight[destination] or (new_weight == next_weight[destination] and (new_profit > next_profit[destination] or (new_profit == next_profit[destination] and new_mask < next_mask[destination]))):
                    next_weight[destination] = new_weight
                    next_mask[destination] = new_mask
                    next_profit[destination] = new_profit

        # Retain only states whose weight strictly improves as q decreases.
        var best_higher_weight = capacity + 1
        for step in range(33):
            let scaled = 32 - step
            if next_weight[scaled] <= capacity and next_weight[scaled] < best_higher_weight:
                best_higher_weight = next_weight[scaled]
            else:
                next_weight[scaled] = capacity + 1
                next_mask[scaled] = 0
                next_profit[scaled] = 0
        for scaled in range(33):
            state_weight[scaled] = next_weight[scaled]
            state_mask[scaled] = next_mask[scaled]
            state_profit[scaled] = next_profit[scaled]

    var best_score: Int64 = -1
    var best_profit: Int64 = -1
    var best_weight = capacity + 1
    var best_mask: Int64 = 0
    for scaled in range(33):
        if state_weight[scaled] > capacity:
            continue
        var remaining = capacity - state_weight[scaled]
        var small_mask: Int64 = 0
        var small_profit: Int64 = 0
        var small_weight: Int64 = 0
        for position in range(small_count):
            let item = small_order[position]
            if weights[item] > remaining:
                break
            remaining -= weights[item]
            small_weight += weights[item]
            small_profit += profits[item]
            small_mask |= Int64(1) << item
        let score = lower_bound * Int64(scaled) + 16 * small_profit
        let total_profit = state_profit[scaled] + small_profit
        let total_weight = state_weight[scaled] + small_weight
        let mask = state_mask[scaled] | small_mask
        if score > best_score or (score == best_score and (total_profit > best_profit or (total_profit == best_profit and (total_weight < best_weight or (total_weight == best_weight and mask < best_mask))))):
            best_score = score
            best_profit = total_profit
            best_weight = total_weight
            best_mask = mask

    return (best_profit << 8) | best_mask
