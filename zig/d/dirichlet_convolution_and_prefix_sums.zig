const modulus: i64 = 998244353;
const max_n: usize = 64;
const max_q: usize = 15;
const max_parseable: usize = 32;

fn prefixValue(q: [max_q]i64, prefix: [max_q]i64, count: usize, value: i64) i64 {
    if (value == 0) return 0;
    for (0..count) |index| {
        if (q[index] == value) return prefix[index];
    }
    return 0;
}

export fn dirichlet_convolution_and_prefix_sums(input_opt: ?[*]const i64,
        length: usize, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_parseable) return -1;
    const input = input_opt.?[0..length];
    if (input[0] < 1 or input[0] > @as(i64, @intCast(max_n))) return -1;
    const n = input[0];
    var descending: [max_q]i64 = @splat(0);
    var count: usize = 0;
    var left: i64 = 1;
    while (left <= n) {
        const value = @divTrunc(n, left);
        descending[count] = value;
        count += 1;
        left = @divTrunc(n, value) + 1;
    }
    var q: [max_q]i64 = @splat(0);
    for (0..count) |index| q[index] = descending[count - 1 - index];
    if (length != 1 + 2 * count) return -1;

    var f: [max_q]i64 = @splat(0);
    var g: [max_q]i64 = @splat(0);
    var results: [max_q]i64 = @splat(0);
    for (0..count) |index| {
        f[index] = input[1 + index];
        g[index] = input[1 + count + index];
        if (f[index] < 1 or f[index] >= modulus or g[index] < 1 or g[index] >= modulus) return -1;
    }

    for (0..count) |out_index| {
        const x = q[out_index];
        var total: i64 = 0;
        var start: i64 = 1;
        while (start <= x) {
            const quotient = @divTrunc(x, start);
            const right = @divTrunc(x, quotient);
            const below = @divTrunc(x, quotient + 1);
            var interval = @mod(prefixValue(q, f, count, right)
                - prefixValue(q, f, count, below), modulus);
            if (interval < 0) interval += modulus;
            var q_index: usize = 0;
            while (q_index < count and q[q_index] != quotient) : (q_index += 1) {}
            if (q_index == count) return -1;
            total = @mod(total + interval * g[q_index], modulus);
            start = right + 1;
        }
        results[out_index] = total;
    }

    const needed = 8 * count;
    const output = output_opt orelse return -2;
    if (output_capacity < needed) return -2;
    for (0..count) |index| {
        const bits: u64 = @bitCast(results[index]);
        for (0..8) |byte| output[8 * index + byte] = @truncate(bits >> @intCast(8 * byte));
    }
    return @intCast(needed);
}
