module knapsack_profit_scaling_small_large_fptas;
const MAX_N = 8, MAX_INPUT = 18, MAX_Q = 128;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b += 1) { output[offset + b] = (char)(bits & 255); bits >>= 8; }
}

long knapsack_profit_scaling_small_large_fptas(long* input, usz length, char* output, usz capacity) @export("knapsack_profit_scaling_small_large_fptas") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long cap = input[0], n64 = input[1];
    if (cap < 1 || cap > 30 || n64 < 1 || n64 > MAX_N || length != 2 + 2 * (usz)n64) return -1;
    usz n = (usz)n64;
    long[MAX_N] weight = zeroed, profit = zeroed;
    for (usz i = 0; i < n; i += 1) {
        weight[i] = input[2 + 2 * i]; profit[i] = input[3 + 2 * i];
        if (weight[i] < 1 || weight[i] > 30 || profit[i] < 1 || profit[i] > 100) return -1;
    }
    if (output == null || capacity < 16) return -2;
    usz[MAX_N] order = zeroed; usz eligible = 0;
    for (usz i = 0; i < n; i += 1) if (weight[i] <= cap) { order[eligible] = i; eligible += 1; }
    for (usz i = 1; i < eligible; i += 1) {
        usz key = order[i], j = i;
        while (j > 0 && profit[key] * weight[order[j - 1]] > profit[order[j - 1]] * weight[key]) { order[j] = order[j - 1]; j -= 1; }
        order[j] = key;
    }
    long upper_num = 0, upper_den = 1, room = cap;
    for (usz k = 0; k < eligible; k += 1) { usz i = order[k]; if (weight[i] <= room) { upper_num += profit[i]; room -= weight[i]; } else { upper_num = upper_num * weight[i] + profit[i] * room; upper_den = weight[i]; break; } }
    usz[MAX_N] small = zeroed, large = zeroed, ns = 0, nl = 0;
    for (usz i = 0; i < n; i += 1) if (weight[i] <= cap) { if (4 * profit[i] * upper_den <= upper_num) { small[ns] = i; ns += 1; } else { large[nl] = i; nl += 1; } }
    for (usz i = 1; i < ns; i += 1) { usz key = small[i], j = i; while (j > 0 && profit[key] * weight[small[j - 1]] > profit[small[j - 1]] * weight[key]) { small[j] = small[j - 1]; j -= 1; } small[j] = key; }
    long[MAX_Q + 1] dpw = zeroed, dpm = zeroed;
    for (usz q = 0; q <= MAX_Q; q += 1) dpw[q] = cap + 1;
    dpw[0] = 0; usz reachable = 0;
    for (usz k = 0; k < nl; k += 1) {
        usz i = large[k], value = upper_num == 0 ? 0 : (usz)(16 * profit[i] * upper_den / upper_num), q = reachable + 1;
        while (q > 0) { q -= 1; if (dpw[q] <= cap) { usz dst = q + value; long nw = dpw[q] + weight[i], nm = dpm[q] | ((long)1 << i); if (nw < dpw[dst] || (nw == dpw[dst] && nm < dpm[dst])) { dpw[dst] = nw; dpm[dst] = nm; } } }
        reachable += value;
    }
    long best_mask = 0, best_profit = 0;
    for (usz q = 0; q <= reachable; q += 1) if (dpw[q] <= cap) {
        long mask = dpm[q], value = 0, remaining = cap - dpw[q];
        for (usz i = 0; i < n; i += 1) if (((ulong)mask >> i) & 1) value += profit[i];
        for (usz k = 0; k < ns; k += 1) { usz i = small[k]; if (weight[i] <= remaining) { remaining -= weight[i]; mask |= (long)1 << i; value += profit[i]; } }
        if (value > best_profit || (value == best_profit && mask < best_mask)) { best_profit = value; best_mask = mask; }
    }
    store_i64_le(output, 0, best_mask); store_i64_le(output, 8, best_profit);
    return 16;
}
