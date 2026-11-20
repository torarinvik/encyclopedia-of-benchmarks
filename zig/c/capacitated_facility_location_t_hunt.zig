const MAX_N: usize = 4;
const MAX_F: usize = 3;
const MAX_Q: usize = 4;
const MAX_P: usize = 7;
const NEG_INF: i64 = -2305843009213693952;

fn putWord(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn capacitated_facility_location_t_hunt(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > 68) return -1;
    const values = input.?;
    const nr = values[0];
    const fr = values[1];
    const qr = values[2];
    const tr = values[3];
    if (nr < 1 or nr > MAX_N or fr < 1 or fr > MAX_F or qr < 1 or qr > MAX_Q or tr < 0 or tr >= fr) return -1;
    const n: usize = @intCast(nr);
    const f: usize = @intCast(fr);
    const q: usize = @intCast(qr);
    const target: usize = @intCast(tr);
    const points = n + f;
    if (length != 4 + points * points + 2 * f + q + n) return -1;
    var d = [_][MAX_P]i64{[_]i64{0} ** MAX_P} ** MAX_P;
    var fee = [_]i64{0} ** MAX_F;
    var caps = [_]i64{0} ** MAX_F;
    var kind = [_]usize{0} ** MAX_Q;
    var assigned = [_]usize{0} ** MAX_N;
    var at: usize = 4;
    for (0..points) |i| {
        for (0..points) |j| {
            const value = values[at];
            at += 1;
            if (value < 0 or value > 1000) return -1;
            d[i][j] = value;
        }
    }
    for (0..points) |i| {
        if (d[i][i] != 0) return -1;
        for (0..points) |j| {
            if (i != j and d[i][j] == 0) return -1;
            if (d[i][j] != d[j][i]) return -1;
            for (0..points) |k| {
                if (d[i][j] > d[i][k] + d[k][j]) return -1;
            }
        }
    }
    for (0..f) |i| { fee[i] = values[at]; at += 1; if (fee[i] < 0 or fee[i] > 1000) return -1; }
    for (0..f) |i| { caps[i] = values[at]; at += 1; if (caps[i] < 1 or caps[i] > nr) return -1; }
    for (0..q) |i| { const value = values[at]; at += 1; if (value < 0 or value >= fr) return -1; kind[i] = @intCast(value); }
    for (0..n) |i| { const value = values[at]; at += 1; if (value < 0 or value >= qr) return -1; assigned[i] = @intCast(value); }
    var weight = [_]i64{0} ** MAX_Q;
    var profit = [_]i64{0} ** MAX_Q;
    var old_cost: i64 = 0;
    for (0..q) |c| { profit[c] = fee[kind[c]]; old_cost += fee[kind[c]]; }
    for (0..n) |u| {
        const c = assigned[u];
        const source = kind[c];
        weight[c] += 1;
        if (weight[c] > caps[source]) return -1;
        const before = d[u][n + source];
        const after = d[u][n + target];
        old_cost += before;
        profit[c] -= after - before;
    }
    var result = [_]i64{ 0, 0, 0, old_cost, old_cost };
    for (1..(n + 1)) |copies| {
        const limit = @min(n, copies * @as(usize, @intCast(caps[target])));
        var dp = [_]i64{NEG_INF} ** (MAX_N + 1);
        var masks = [_]u32{0} ** (MAX_N + 1);
        dp[0] = 0;
        for (0..q) |item| {
            var next = dp;
            var next_masks = masks;
            const iw: usize = @intCast(weight[item]);
            if (iw <= limit) {
                for (0..limit - iw + 1) |used| {
                    if (dp[used] == NEG_INF) continue;
                    const nw = used + iw;
                    const value = dp[used] + profit[item];
                    const mask = masks[used] | (@as(u32, 1) << @as(u5, @intCast(item)));
                    if (value > next[nw] or (value == next[nw] and mask < next_masks[nw])) {
                        next[nw] = value;
                        next_masks[nw] = mask;
                    }
                }
            }
            dp = next;
            masks = next_masks;
        }
        var best = NEG_INF;
        var best_mask: u32 = 0;
        for (0..limit + 1) |used| {
            if (dp[used] > best or (dp[used] == best and masks[used] < best_mask)) {
                best = dp[used];
                best_mask = masks[used];
            }
        }
        if (best > @as(i64, @intCast(copies)) * fee[target]) {
            result = .{ 1, @intCast(copies), @intCast(best_mask), old_cost,
                old_cost + @as(i64, @intCast(copies)) * fee[target] - best };
            break;
        }
    }
    if (output == null or capacity < 40) return -2;
    for (0..5) |i| putWord(output.?, i * 8, result[i]);
    return 40;
}
