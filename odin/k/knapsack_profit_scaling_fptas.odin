package knapsack_profit_scaling_fptas
import "core:c"

Max_N :: 12
Max_Input :: 26
Max_Q :: 576

store_i64_le :: proc(out: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for b in 0..<8 { out[offset+b] = u8(bits & 255); bits >>= 8 }
}

@(export)
knapsack_profit_scaling_fptas :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > Max_Input do return -1
    cap := input[0]; n64 := input[1]
    if cap < 1 || cap > 100 || n64 < 1 || n64 > Max_N || length != c.size_t(2 + 2 * int(n64)) do return -1
    n := int(n64)
    weights: [Max_N]i64
    profits: [Max_N]i64
    for i in 0..<n {
        weights[i] = input[2+2*i]; profits[i] = input[3+2*i]
        if weights[i] < 1 || weights[i] > 100 || profits[i] < 1 || profits[i] > 10000 do return -1
    }
    if output == nil || capacity < 16 do return -2
    order: [Max_N]int
    eligible := 0
    for i in 0..<n { if weights[i] <= cap { order[eligible] = i; eligible += 1 } }
    for i in 1..<eligible {
        key := order[i]; j := i
        for j > 0 && profits[key]*weights[order[j-1]] > profits[order[j-1]]*weights[key] { order[j] = order[j-1]; j -= 1 }
        order[j] = key
    }
    upper: i64 = 0; room := cap
    for k in 0..<eligible {
        i := order[k]
        if weights[i] <= room { upper += profits[i]; room -= weights[i] }
        else { upper += profits[i]*room/weights[i]; break }
    }
    dp_weight: [Max_Q+1]i64
    dp_mask: [Max_Q+1]i64
    for q in 0..=Max_Q { dp_weight[q] = cap+1 }
    dp_weight[0] = 0; reachable := 0
    for i in 0..<n {
        if weights[i] > cap || upper == 0 do continue
        value := int(4*i64(n)*profits[i]/upper)
        if value == 0 do continue
        q := reachable
        for {
            old_weight := dp_weight[q]
            if old_weight <= cap {
                next := q+value; new_weight := old_weight+weights[i]; new_mask := dp_mask[q] | (i64(1)<<i)
                if new_weight < dp_weight[next] || new_weight == dp_weight[next] && new_mask < dp_mask[next] {
                    dp_weight[next] = new_weight; dp_mask[next] = new_mask
                }
            }
            if q == 0 do break
            q -= 1
        }
        reachable += value
    }
    best := 0
    for q in 1..=Max_Q { if dp_weight[q] <= cap { best = q } }
    mask := dp_mask[best]; selected_profit: i64 = 0
    for i in 0..<n { if (u64(mask)>>i)&1 != 0 { selected_profit += profits[i] } }
    store_i64_le(output,0,mask); store_i64_le(output,8,selected_profit)
    return 16
}
