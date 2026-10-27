const MAX_N: usize = 8;
const MAX_INPUT: usize = 18;
const MAX_Q: usize = 128;

fn store(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[offset + b] = @truncate(bits >> @intCast(8 * b));
}

export fn knapsack_profit_scaling_small_large_fptas(input_opt: ?[*]const i64, length: usize,
        output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MAX_INPUT) return -1;
    const input = input_opt.?; const cap = input[0]; const n64 = input[1];
    if (cap < 1 or cap > 30 or n64 < 1 or n64 > MAX_N or length != 2 + 2 * @as(usize, @intCast(n64))) return -1;
    const n: usize = @intCast(n64);
    var weights: [MAX_N]i64 = [_]i64{0} ** MAX_N; var profits: [MAX_N]i64 = [_]i64{0} ** MAX_N;
    for (0..n) |i| { weights[i] = input[2 + 2*i]; profits[i] = input[3 + 2*i]; if (weights[i] < 1 or weights[i] > 30 or profits[i] < 1 or profits[i] > 100) return -1; }
    if (output_opt == null or capacity < 16) return -2;
    var order: [MAX_N]usize = [_]usize{0} ** MAX_N; var eligible: usize = 0;
    for (0..n) |i| { if (weights[i] <= cap) { order[eligible] = i; eligible += 1; } }
    for (1..eligible) |i| { const key = order[i]; var j = i; while (j > 0 and profits[key]*weights[order[j-1]] > profits[order[j-1]]*weights[key]) { order[j] = order[j-1]; j -= 1; } order[j] = key; }
    var upper_num: i64 = 0; var upper_den: i64 = 1; var room = cap;
    for (0..eligible) |k| { const i = order[k]; if (weights[i] <= room) { upper_num += profits[i]; room -= weights[i]; } else { upper_num = upper_num*weights[i]+profits[i]*room; upper_den = weights[i]; break; } }
    var small: [MAX_N]usize = [_]usize{0} ** MAX_N; var large: [MAX_N]usize = [_]usize{0} ** MAX_N; var ns: usize = 0; var nl: usize = 0;
    for (0..n) |i| { if (weights[i] <= cap) { if (4*profits[i]*upper_den <= upper_num) { small[ns] = i; ns += 1; } else { large[nl] = i; nl += 1; } } }
    for (1..ns) |i| { const key = small[i]; var j = i; while (j > 0 and profits[key]*weights[small[j-1]] > profits[small[j-1]]*weights[key]) { small[j] = small[j-1]; j -= 1; } small[j] = key; }
    var dpw: [MAX_Q + 1]i64 = undefined; var dpm: [MAX_Q + 1]i64 = [_]i64{0} ** (MAX_Q + 1);
    for (0..MAX_Q+1) |q| dpw[q] = cap + 1;
    dpw[0] = 0; var reachable: usize = 0;
    for (0..nl) |k| { const i = large[k]; const value: usize = if (upper_num > 0) @intCast(@divTrunc(16*profits[i]*upper_den, upper_num)) else 0; var q = reachable + 1; while (q > 0) { q -= 1; if (dpw[q] <= cap) { const dst = q + value; const nw = dpw[q] + weights[i]; const nm = dpm[q] | (@as(i64, 1) << @intCast(i)); if (nw < dpw[dst] or (nw == dpw[dst] and nm < dpm[dst])) { dpw[dst] = nw; dpm[dst] = nm; } } } reachable += value; }
    var best_mask: i64 = 0; var best_profit: i64 = 0;
    for (0..reachable+1) |q| { if (dpw[q] <= cap) { var mask = dpm[q]; var value: i64 = 0; var remaining = cap - dpw[q]; for (0..n) |i| { if (((@as(u64, @bitCast(mask)) >> @intCast(i)) & 1) != 0) value += profits[i]; } for (0..ns) |k| { const i = small[k]; if (weights[i] <= remaining) { remaining -= weights[i]; mask |= @as(i64, 1) << @intCast(i); value += profits[i]; } } if (value > best_profit or (value == best_profit and mask < best_mask)) { best_profit = value; best_mask = mask; } } }
    const output = output_opt.?; store(output, 0, best_mask); store(output, 8, best_profit); return 16;
}
