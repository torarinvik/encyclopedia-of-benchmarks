const INVALID_RESULT: f64 = -1.0e300;
const MAX_INPUT_LENGTH: usize = 36;
const MAX_SAMPLES: i64 = 32;

fn sampleF32(q: i64) f32 {
    return @as(f32, @floatFromInt(q)) / 16.0;
}

export fn realtime_stats(input: ?[*]const i64, length: usize) f64 {
    const values = input orelse return INVALID_RESULT;
    if (length < 3 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const variant = values[0];
    const statistic = values[1];
    const count = values[2];
    if (variant < 0 or variant > 2 or statistic < 0 or statistic > 2 or
        count < 2 or count > MAX_SAMPLES or length != @as(usize, @intCast(3 + count)))
        return INVALID_RESULT;
    const sample_count: usize = @intCast(count);
    for (0..sample_count) |i| {
        if (values[3 + i] < -64 or values[3 + i] > 64) return INVALID_RESULT;
    }

    var mean32: f32 = 0.0;
    var variance32: f32 = 0.0;
    var mean64: f64 = 0.0;
    var variance64: f64 = 0.0;
    if (variant == 0) {
        var anchor: f32 = 0.0;
        var ex: f32 = 0.0;
        var ex2: f32 = 0.0;
        var n: usize = 0;
        for (0..sample_count) |i| {
            const x = sampleF32(values[3 + i]);
            if (n == 0) anchor = x;
            n += 1;
            const tmp = x - anchor;
            ex += tmp;
            ex2 += tmp * tmp;
        }
        const n32: f32 = @floatFromInt(n);
        mean32 = anchor + ex / n32;
        variance32 = (ex2 - (ex * ex) / n32) / @as(f32, @floatFromInt(n - 1));
    } else if (variant == 1) {
        var mu: f32 = 0.0;
        var m: f32 = 0.0;
        var n: usize = 0;
        for (0..sample_count) |i| {
            const x = sampleF32(values[3 + i]);
            n += 1;
            const delta = x - mu;
            mu += delta / @as(f32, @floatFromInt(n));
            const delta2 = x - mu;
            m += delta * delta2;
        }
        mean32 = mu;
        variance32 = m / @as(f32, @floatFromInt(n));
    } else {
        var mu: f64 = 0.0;
        var m: f64 = 0.0;
        var n: usize = 0;
        for (0..sample_count) |i| {
            const x: f64 = sampleF32(values[3 + i]);
            n += 1;
            const delta = x - mu;
            mu += delta / @as(f64, @floatFromInt(n));
            const delta2 = x - mu;
            m += delta * delta2;
        }
        mean64 = mu;
        variance64 = m / @as(f64, @floatFromInt(n));
    }

    if (variant < 2) {
        if (statistic == 0) return @as(f64, @floatCast(mean32));
        if (statistic == 1) return @as(f64, @floatCast(variance32));
        return @as(f64, @floatCast(@sqrt(variance32)));
    }
    if (statistic == 0) return mean64;
    if (statistic == 1) return variance64;
    return @sqrt(variance64);
}
