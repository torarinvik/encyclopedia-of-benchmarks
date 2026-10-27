module knapsack_profit_scaling_fptas;
const MAX_N = 12, MAX_INPUT = 26, MAX_Q = 576;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b += 1) { output[offset + b] = (char)(bits & 255); bits >>= 8; }
}

long knapsack_profit_scaling_fptas(long* input, usz length, char* output, usz capacity) @export("knapsack_profit_scaling_fptas") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long cap = input[0], n64 = input[1];
    if (cap < 1 || cap > 100 || n64 < 1 || n64 > MAX_N || length != 2 + 2 * (usz)n64) return -1;
    usz n = (usz)n64;
    long[MAX_N] weight = zeroed, profit = zeroed;
    for (usz i = 0; i < n; i += 1) {
        weight[i] = input[2 + 2 * i]; profit[i] = input[3 + 2 * i];
        if (weight[i] < 1 || weight[i] > 100 || profit[i] < 1 || profit[i] > 10000) return -1;
    }
    if (output == null || capacity < 16) return -2;
    usz[MAX_N] order = zeroed;
    usz eligible = 0;
    for (usz i = 0; i < n; i += 1) if (weight[i] <= cap) { order[eligible] = i; eligible += 1; }
    for (usz i = 1; i < eligible; i += 1) {
        usz key = order[i], j = i;
        while (j > 0 && profit[key] * weight[order[j - 1]] > profit[order[j - 1]] * weight[key]) {
            order[j] = order[j - 1]; j -= 1;
        }
        order[j] = key;
    }
    long upper = 0, room = cap;
    for (usz k = 0; k < eligible; k += 1) {
        usz i = order[k];
        if (weight[i] <= room) { upper += profit[i]; room -= weight[i]; }
        else { upper += profit[i] * room / weight[i]; break; }
    }
    long[MAX_Q + 1] dp_weight = zeroed, dp_mask = zeroed;
    for (usz q = 0; q <= MAX_Q; q += 1) dp_weight[q] = cap + 1;
    dp_weight[0] = 0; usz reachable = 0;
    for (usz i = 0; i < n; i += 1) {
        if (weight[i] > cap || upper == 0) continue;
        usz value = (usz)(4 * (long)n * profit[i] / upper);
        if (value == 0) continue;
        usz q = reachable + 1;
        while (q > 0) {
            q -= 1;
            if (dp_weight[q] > cap) continue;
            usz next = q + value;
            long next_weight = dp_weight[q] + weight[i], next_mask = dp_mask[q] | ((long)1 << i);
            if (next_weight < dp_weight[next] || (next_weight == dp_weight[next] && next_mask < dp_mask[next])) {
                dp_weight[next] = next_weight; dp_mask[next] = next_mask;
            }
        }
        reachable += value;
    }
    usz best = 0;
    for (usz q = 1; q <= MAX_Q; q += 1) if (dp_weight[q] <= cap) best = q;
    long mask = dp_mask[best], selected_profit = 0;
    for (usz i = 0; i < n; i += 1) if (((ulong)mask >> i) & 1) selected_profit += profit[i];
    store_i64_le(output, 0, mask); store_i64_le(output, 8, selected_profit);
    return 16;
}
