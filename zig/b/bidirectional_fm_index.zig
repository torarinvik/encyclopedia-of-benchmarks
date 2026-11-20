const Index = struct {
    cumulative: [5]usize = [_]usize{0} ** 5,
    bwt: [65]i64 = [_]i64{0} ** 65,
};

fn suffixLess(s: *const [65]i64, total: usize, a0: usize, b0: usize) bool {
    var a = a0;
    var b = b0;
    while (a < total and b < total) {
        if (s[a] != s[b]) return s[a] < s[b];
        a += 1;
        b += 1;
    }
    return a == total and b != total;
}

fn buildIndex(s: *const [65]i64, total: usize) Index {
    var result = Index{};
    var suffixes: [65]usize = undefined;
    var frequency = [_]usize{0} ** 5;
    for (0..total) |i| suffixes[i] = i;
    for (1..total) |i| {
        const key = suffixes[i];
        var j = i;
        while (j > 0 and suffixLess(s, total, key, suffixes[j - 1])) {
            suffixes[j] = suffixes[j - 1];
            j -= 1;
        }
        suffixes[j] = key;
    }
    for (0..total) |i| {
        result.bwt[i] = s[(suffixes[i] + total - 1) % total];
        frequency[@intCast(result.bwt[i])] += 1;
    }
    var seen: usize = 0;
    for (0..5) |symbol| {
        result.cumulative[symbol] = seen;
        seen += frequency[symbol];
    }
    return result;
}

fn rankBefore(index: *const Index, end: usize, symbol: usize) usize {
    var count: usize = 0;
    for (0..end) |i| if (@as(usize, @intCast(index.bwt[i])) == symbol) { count += 1; };
    return count;
}

export fn bidirectional_fm_index(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > 195) return -1;
    const n0 = input[0];
    const q0 = input[1];
    if (n0 < 0 or n0 > 64 or q0 < 0 or q0 > 64) return -1;
    const n: usize = @intCast(n0);
    const q: usize = @intCast(q0);
    if (length != 2 + n + 2 * q) return -1;
    var forward_text: [65]i64 = [_]i64{0} ** 65;
    var reverse_text: [65]i64 = [_]i64{0} ** 65;
    for (0..n) |i| {
        const symbol = input[2 + i];
        if (symbol < 1 or symbol > 4) return -1;
        forward_text[i] = symbol;
        reverse_text[n - 1 - i] = symbol;
    }
    forward_text[n] = 0;
    reverse_text[n] = 0;
    for (0..q) |op| {
        const side = input[2 + n + 2 * op];
        const symbol = input[3 + n + 2 * op];
        if ((side != 0 and side != 1) or symbol < 1 or symbol > 4) return -1;
    }
    const total = n + 1;
    const forward = buildIndex(&forward_text, total);
    const reverse = buildIndex(&reverse_text, total);
    var fl: usize = 0;
    var fr = total;
    var rl: usize = 0;
    var rr = total;
    var checksum: i64 = 0;
    for (0..q) |op| {
        const side: usize = @intCast(input[2 + n + 2 * op]);
        const symbol: usize = @intCast(input[3 + n + 2 * op]);
        const old_fl = fl;
        const old_fr = fr;
        const old_rl = rl;
        const old_rr = rr;
        if (side == 0) {
            fl = forward.cumulative[symbol] + rankBefore(&forward, old_fl, symbol);
            fr = forward.cumulative[symbol] + rankBefore(&forward, old_fr, symbol);
            var start = old_rl;
            for (0..symbol) |smaller| start += rankBefore(&forward, old_fr, smaller) - rankBefore(&forward, old_fl, smaller);
            const count = rankBefore(&forward, old_fr, symbol) - rankBefore(&forward, old_fl, symbol);
            rl = start;
            rr = start + count;
        } else {
            rl = reverse.cumulative[symbol] + rankBefore(&reverse, old_rl, symbol);
            rr = reverse.cumulative[symbol] + rankBefore(&reverse, old_rr, symbol);
            var start = old_fl;
            for (0..symbol) |smaller| start += rankBefore(&reverse, old_rr, smaller) - rankBefore(&reverse, old_rl, smaller);
            const count = rankBefore(&reverse, old_rr, symbol) - rankBefore(&reverse, old_rl, symbol);
            fl = start;
            fr = start + count;
        }
        checksum += @as(i64, @intCast(op + 1)) * @as(i64, @intCast(fr - fl));
    }
    return checksum;
}
