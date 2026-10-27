package knapsack_profit_scaling_small_large_fptas
import "core:c"

Max_N :: 8
Max_Input :: 18
Max_Q :: 128

store_i64_le :: proc(out: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for b in 0..<8 { out[offset+b] = u8(bits & 255); bits >>= 8 }
}

@(export)
knapsack_profit_scaling_small_large_fptas :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > Max_Input do return -1
    cap := input[0]; n64 := input[1]
    if cap < 1 || cap > 30 || n64 < 1 || n64 > Max_N || length != c.size_t(2+2*int(n64)) do return -1
    n := int(n64)
    weights: [Max_N]i64; profits: [Max_N]i64
    for i in 0..<n { weights[i] = input[2+2*i]; profits[i] = input[3+2*i]; if weights[i] < 1 || weights[i] > 30 || profits[i] < 1 || profits[i] > 100 do return -1 }
    if output == nil || capacity < 16 do return -2
    order: [Max_N]int; eligible := 0
    for i in 0..<n { if weights[i] <= cap { order[eligible] = i; eligible += 1 } }
    for i in 1..<eligible { key := order[i]; j := i; for j > 0 && profits[key]*weights[order[j-1]] > profits[order[j-1]]*weights[key] { order[j] = order[j-1]; j -= 1 }; order[j] = key }
    upper_num: i64 = 0; upper_den: i64 = 1; room := cap
    for k in 0..<eligible { i := order[k]; if weights[i] <= room { upper_num += profits[i]; room -= weights[i] } else { upper_num = upper_num*weights[i]+profits[i]*room; upper_den = weights[i]; break } }
    small: [Max_N]int; large: [Max_N]int; ns := 0; nl := 0
    for i in 0..<n { if weights[i] <= cap { if 4*profits[i]*upper_den <= upper_num { small[ns] = i; ns += 1 } else { large[nl] = i; nl += 1 } } }
    for i in 1..<ns { key := small[i]; j := i; for j > 0 && profits[key]*weights[small[j-1]] > profits[small[j-1]]*weights[key] { small[j] = small[j-1]; j -= 1 }; small[j] = key }
    dpw: [Max_Q+1]i64; dpm: [Max_Q+1]i64
    for q in 0..=Max_Q { dpw[q] = cap+1 }
    dpw[0] = 0; reachable := 0
    for k in 0..<nl {
        i := large[k]; value := 0; if upper_num > 0 { value = int(16*profits[i]*upper_den/upper_num) }
        q := reachable
        for { if dpw[q] <= cap { dst := q+value; nw := dpw[q]+weights[i]; nm := dpm[q] | (i64(1)<<i); if nw < dpw[dst] || (nw == dpw[dst] && nm < dpm[dst]) { dpw[dst] = nw; dpm[dst] = nm } }; if q == 0 do break; q -= 1 }
        reachable += value
    }
    best_mask: i64 = 0; best_profit: i64 = 0
    for q in 0..=reachable { if dpw[q] <= cap { mask := dpm[q]; value: i64 = 0; remaining := cap-dpw[q]; for i in 0..<n { if (u64(mask)>>i)&1 != 0 { value += profits[i] } }; for k in 0..<ns { i := small[k]; if weights[i] <= remaining { remaining -= weights[i]; mask |= i64(1)<<i; value += profits[i] } }; if value > best_profit || (value == best_profit && mask < best_mask) { best_profit = value; best_mask = mask } } }
    store_i64_le(output,0,best_mask); store_i64_le(output,8,best_profit)
    return 16
}
