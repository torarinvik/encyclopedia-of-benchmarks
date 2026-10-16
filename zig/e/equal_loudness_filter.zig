const A = [_]i64{1073741824,-3875279605,7242592440,-9849938776,11019995787,-10310050823,8022431451,-5130046574,2558322377,-874363774,153873500};
const B = [_]i64{60930872,-44894685,-5549718,-9621322,-7681698,30506759,-32060412,22380311,-4826655,8028337,-4488672};
const HA = [_]i64{1089966811,-2146993250,1057516837};
const HB = [_]i64{1073619225,-2147238449,1073619225};

export fn equal_loudness_filter(v: ?[*]const i64, n: usize) callconv(.c) i64 {
    if (v == null or n < 1 or n > 33) return -1;
    const s = v.?;
    const count = s[0];
    if (count < 0 or count > 32 or n != @as(usize, @intCast(count)) + 1) return -1;
    const count_usize: usize = @intCast(count);
    var x: [10]i64 = @splat(0);
    var y: [10]i64 = @splat(0);
    var hx: [2]i64 = @splat(0);
    var hy: [2]i64 = @splat(0);
    var output: i64 = 0;
    for (0..count_usize) |i| {
        const sample = s[i + 1];
        if (sample < -1000000 or sample > 1000000) return -1;
        const mid = step(sample, &A, &B, 10, &x, &y);
        output = step(mid, &HA, &HB, 2, &hx, &hy);
    }
    return output;
}

fn step(sample: i64, a: []const i64, b: []const i64, order: usize, x: []i64, y: []i64) i64 {
    var acc = b[0] * sample;
    for (1..order + 1) |i| acc += b[i] * x[i - 1] - a[i] * y[i - 1];
    const out = @divTrunc(acc, a[0]);
    var i = order;
    while (i > 1) {
        x[i - 1] = x[i - 2];
        y[i - 1] = y[i - 2];
        i -= 1;
    }
    if (order > 0) {
        x[0] = sample;
        y[0] = out;
    }
    return out;
}
