const MAX_N: usize = 12;
const MAX_INPUT: usize = 26;
const MAX_Q: usize = 576;

fn store(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[offset + b] = @truncate(bits >> @intCast(8 * b));
}

export fn knapsack_profit_scaling_fptas(input_opt: ?[*]const i64, length: usize,
        output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const cap = input[0]; const n64 = input[1];
    if (cap < 1 or cap > 100 or n64 < 1 or n64 > MAX_N
        or length != 2 + 2 * @as(usize, @intCast(n64))) return -1;
    const n: usize = @intCast(n64);
    var weights: [MAX_N]i64 = [_]i64{0} ** MAX_N;
    var profits: [MAX_N]i64 = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        weights[i] = input[2 + 2 * i]; profits[i] = input[3 + 2 * i];
        if (weights[i] < 1 or weights[i] > 100 or profits[i] < 1 or profits[i] > 10000) return -1;
    }
    if (output_opt == null or capacity < 16) return -2;
    var order: [MAX_N]usize = [_]usize{0} ** MAX_N;
    var eligible: usize = 0;
    for (0..n) |i| { if (weights[i] <= cap) { order[eligible] = i; eligible += 1; } }
    for (1..eligible) |i| {
        const key = order[i]; var j = i;
        while (j > 0 and profits[key] * weights[order[j - 1]] > profits[order[j - 1]] * weights[key]) {
            order[j] = order[j - 1]; j -= 1;
        }
        order[j] = key;
    }
    var upper: i64 = 0; var room = cap;
    for (0..eligible) |k| {
        const i = order[k];
        if (weights[i] <= room) { upper += profits[i]; room -= weights[i]; }
        else { upper += @divTrunc(profits[i] * room, weights[i]); break; }
    }
    var dp_weight: [MAX_Q + 1]i64 = undefined;
    var dp_mask: [MAX_Q + 1]i64 = [_]i64{0} ** (MAX_Q + 1);
    for (0..MAX_Q + 1) |q| dp_weight[q] = cap + 1;
    dp_weight[0] = 0; var reachable: usize = 0;
    for (0..n) |i| {
        if (weights[i] > cap or upper == 0) continue;
        const value: usize = @intCast(@divTrunc(4 * @as(i64, @intCast(n)) * profits[i], upper));
        if (value == 0) continue;
        var q = reachable + 1;
        while (q > 0) {
            q -= 1;
            if (dp_weight[q] <= cap) {
                const next = q + value; const nw = dp_weight[q] + weights[i];
                const nm = dp_mask[q] | (@as(i64, 1) << @intCast(i));
                if (nw < dp_weight[next] or (nw == dp_weight[next] and nm < dp_mask[next])) {
                    dp_weight[next] = nw; dp_mask[next] = nm;
                }
            }
        }
        reachable += value;
    }
    var best: usize = 0;
    for (1..MAX_Q + 1) |q| { if (dp_weight[q] <= cap) best = q; }
    const mask = dp_mask[best]; var selected_profit: i64 = 0;
    for (0..n) |i| { if (((@as(u64, @bitCast(mask)) >> @intCast(i)) & 1) != 0) selected_profit += profits[i]; }
    const output = output_opt.?;
    store(output, 0, mask); store(output, 8, selected_profit);
    return 16;
}
