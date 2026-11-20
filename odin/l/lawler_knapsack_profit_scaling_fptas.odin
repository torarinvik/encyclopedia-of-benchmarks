package lawler_knapsack_profit_scaling_fptas
import "core:c"

Max_N :: 8
Max_Input :: 19
Max_Q :: 32

@(export)
lawler_knapsack_profit_scaling_fptas :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > Max_Input do return -1
    capacity := input[0]
    n64 := input[1]
    if capacity < 1 || capacity > 30 || n64 < 4 || n64 > Max_N ||
       length != c.size_t(2 + 2*int(n64)) do return -1
    n := int(n64)
    weight: [Max_N]i64
    profit: [Max_N]i64
    for i in 0..<n {
        weight[i] = input[2+2*i]
        profit[i] = input[3+2*i]
        if weight[i] < 1 || weight[i] > capacity || profit[i] < 32 || profit[i] > 200 do return -1
    }

    order: [Max_N]int
    for i in 0..<n { order[i] = i }
    for i in 1..<n {
        key := order[i]
        j := i
        for j > 0 {
            previous := order[j-1]
            left := profit[key]*weight[previous]
            right := profit[previous]*weight[key]
            if left < right || left == right && key > previous do break
            order[j] = previous
            j -= 1
        }
        order[j] = key
    }

    prefix_weight: i64 = 0
    prefix_profit: i64 = 0
    prefix_mask: i64 = 0
    p0: i64 = 0
    exact := true
    for position in 0..<n {
        item := order[position]
        if prefix_weight+weight[item] > capacity {
            exact = false
            p0 = prefix_profit
            for i in 0..<n { if profit[i] > p0 { p0 = profit[i] } }
            break
        }
        prefix_weight += weight[item]
        prefix_profit += profit[item]
        prefix_mask |= i64(1) << item
        if prefix_weight == capacity do break
    }
    if exact do return (prefix_profit << 8) | prefix_mask

    small: [Max_N]int
    small_count := 0
    groups: [Max_Q+1][Max_N]int
    group_count: [Max_Q+1]int
    for item in 0..<n {
        if 4*profit[item] <= p0 {
            small[small_count] = item
            small_count += 1
        } else {
            scaled := 0
            for exponent in 0..=1 {
                scale := 1 << exponent
                if i64(scale)*p0 < 4*profit[item] && 4*profit[item] <= 2*i64(scale)*p0 {
                    scaled = scale*int(16*profit[item]/(i64(scale)*p0))
                    break
                }
            }
            if scaled <= 0 || scaled > Max_Q do return -1
            groups[scaled][group_count[scaled]] = item
            group_count[scaled] += 1
        }
    }

    ordered_small: [Max_N]int
    ordered_small_count := 0
    for position in 0..<n {
        item := order[position]
        for j in 0..<small_count {
            if small[j] == item {
                ordered_small[ordered_small_count] = item
                ordered_small_count += 1
                break
            }
        }
    }

    state_weight: [Max_Q+1]i64
    state_mask: [Max_Q+1]i64
    state_profit: [Max_Q+1]i64
    for q in 0..=Max_Q { state_weight[q] = capacity+1 }
    state_weight[0] = 0
    for q := Max_Q; q >= 1; q -= 1 {
        if group_count[q] == 0 do continue
        for i in 1..<group_count[q] {
            key := groups[q][i]
            j := i
            for j > 0 && (weight[groups[q][j-1]] > weight[key] ||
                weight[groups[q][j-1]] == weight[key] && groups[q][j-1] > key) {
                groups[q][j] = groups[q][j-1]
                j -= 1
            }
            groups[q][j] = key
        }
        kept := group_count[q]
        limit := Max_Q/q
        if kept > limit do kept = limit
        next_weight: [Max_Q+1]i64
        next_mask: [Max_Q+1]i64
        next_profit: [Max_Q+1]i64
        for dst in 0..=Max_Q { next_weight[dst] = capacity+1 }
        for old_q in 0..=Max_Q {
            if state_weight[old_q] > capacity do continue
            nw := state_weight[old_q]
            nm := state_mask[old_q]
            np := state_profit[old_q]
            if nw < next_weight[old_q] || nw == next_weight[old_q] &&
                (np > next_profit[old_q] || np == next_profit[old_q] && nm < next_mask[old_q]) {
                next_weight[old_q] = nw
                next_mask[old_q] = nm
                next_profit[old_q] = np
            }
            added_weight: i64 = 0
            added_profit: i64 = 0
            added_mask: i64 = 0
            for take in 0..<kept {
                item := groups[q][take]
                added_weight += weight[item]
                if state_weight[old_q]+added_weight > capacity do break
                added_profit += profit[item]
                added_mask |= i64(1) << item
                dst := old_q+q*(take+1)
                if dst > Max_Q do continue
                nw = state_weight[old_q]+added_weight
                nm = state_mask[old_q]|added_mask
                np = state_profit[old_q]+added_profit
                if nw < next_weight[dst] || nw == next_weight[dst] &&
                    (np > next_profit[dst] || np == next_profit[dst] && nm < next_mask[dst]) {
                    next_weight[dst] = nw
                    next_mask[dst] = nm
                    next_profit[dst] = np
                }
            }
        }
        best_higher_weight := capacity+1
        for scaled := Max_Q; scaled >= 0; scaled -= 1 {
            if next_weight[scaled] <= capacity && next_weight[scaled] < best_higher_weight {
                best_higher_weight = next_weight[scaled]
            } else {
                next_weight[scaled] = capacity+1
                next_mask[scaled] = 0
                next_profit[scaled] = 0
            }
        }
        state_weight = next_weight
        state_mask = next_mask
        state_profit = next_profit
    }

    best_score: i64 = -1
    best_profit: i64 = -1
    best_weight := capacity+1
    best_mask: i64 = 0
    for q in 0..=Max_Q {
        if state_weight[q] > capacity do continue
        used := state_weight[q]
        actual_profit := state_profit[q]
        mask := state_mask[q]
        for j in 0..<ordered_small_count {
            item := ordered_small[j]
            if used+weight[item] > capacity do break
            used += weight[item]
            actual_profit += profit[item]
            mask |= i64(1) << item
        }
        small_profit := actual_profit-state_profit[q]
        score := p0*i64(q)+16*small_profit
        if score > best_score || score == best_score &&
            (actual_profit > best_profit || actual_profit == best_profit &&
             (used < best_weight || used == best_weight && mask < best_mask)) {
            best_score = score
            best_profit = actual_profit
            best_weight = used
            best_mask = mask
        }
    }
    return (best_profit << 8) | best_mask
}
