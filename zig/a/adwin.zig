const MAX_SAMPLES: usize = 256;
const MAX_LEVELS: usize = 16;
const MAX_BUCKETS: usize = 5;
const BUCKET_CAPACITY: usize = MAX_BUCKETS + 1;
const MIN_SUBWINDOW: i64 = 5;
const INPUT_SCALE: f64 = 1_000_000_000.0;

const Adwin = struct {
    sizes: [MAX_LEVELS]usize = @splat(0),
    totals: [MAX_LEVELS][BUCKET_CAPACITY]f64 = @splat(@splat(0.0)),
    variances: [MAX_LEVELS][BUCKET_CAPACITY]f64 = @splat(@splat(0.0)),
    width: i64 = 0,
    total: f64 = 0.0,
    variance: f64 = 0.0,
    bucket_count: usize = 0,
    delta: f64 = 0.0,
};

fn adwinSqrt(value: f64) f64 {
    if (value <= 0.0) return 0.0;
    var root: f64 = if (value > 1.0) value else 1.0;
    for (0..80) |_| root = 0.5 * (root + value / root);
    return root;
}

fn adwinLn(input_value: f64) f64 {
    var value = input_value;
    var exponent: i32 = 0;
    while (value >= 2.0) : (exponent += 1) value *= 0.5;
    const ratio = (value - 1.0) / (value + 1.0);
    const square = ratio * ratio;
    var term = ratio;
    var sum: f64 = 0.0;
    for (0..40) |iteration| {
        sum += term / @as(f64, @floatFromInt(2 * iteration + 1));
        term *= square;
    }
    return 2.0 * sum + @as(f64, @floatFromInt(exponent)) * 0.693147180559945309417232121458176568;
}

fn addBucket(state: *Adwin, level: usize, total: f64, variance: f64) void {
    const slot = state.sizes[level];
    state.totals[level][slot] = total;
    state.variances[level][slot] = variance;
    state.sizes[level] += 1;
}

fn removeOldest(state: *Adwin, level: usize, count: usize) void {
    const old_size = state.sizes[level];
    for (count..old_size) |i| {
        state.totals[level][i - count] = state.totals[level][i];
        state.variances[level][i - count] = state.variances[level][i];
    }
    state.sizes[level] -= count;
}

fn compress(state: *Adwin) void {
    for (0..MAX_LEVELS - 1) |level| {
        if (state.sizes[level] <= MAX_BUCKETS) break;
        const size = @as(f64, @floatFromInt(@as(usize, 1) << @intCast(level)));
        const first_mean = state.totals[level][0] / size;
        const second_mean = state.totals[level][1] / size;
        const difference = first_mean - second_mean;
        const merged_variance = state.variances[level][0] + state.variances[level][1] +
            size * size * difference * difference / (size + size);
        const merged_total = state.totals[level][0] + state.totals[level][1];
        addBucket(state, level + 1, merged_total, merged_variance);
        removeOldest(state, level, 2);
        state.bucket_count -= 1;
    }
}

fn insert(state: *Adwin, value: f64) void {
    state.width += 1;
    addBucket(state, 0, value, 0.0);
    state.bucket_count += 1;
    if (state.width > 1) {
        const deviation = value - state.total / @as(f64, @floatFromInt(state.width - 1));
        state.variance += @as(f64, @floatFromInt(state.width - 1)) * deviation * deviation /
            @as(f64, @floatFromInt(state.width));
    }
    state.total += value;
    compress(state);
}

fn significant(state: *const Adwin, old_width: i64, recent_width: i64, difference: f64) bool {
    const harmonic = 1.0 / @as(f64, @floatFromInt(old_width - MIN_SUBWINDOW + 1)) +
        1.0 / @as(f64, @floatFromInt(recent_width - MIN_SUBWINDOW + 1));
    const confidence = adwinLn(2.0 * adwinLn(@as(f64, @floatFromInt(state.width))) / state.delta);
    const window_variance = state.variance / @as(f64, @floatFromInt(state.width));
    const epsilon = adwinSqrt(2.0 * harmonic * window_variance * confidence) +
        2.0 / 3.0 * confidence * harmonic;
    return @abs(difference) > epsilon;
}

fn dropOldest(state: *Adwin) void {
    var level: usize = MAX_LEVELS - 1;
    while (level > 0 and state.sizes[level] == 0) : (level -= 1) {}
    const bucket_size: i64 = @intCast(@as(usize, 1) << @intCast(level));
    const bucket_total = state.totals[level][0];
    state.width -= bucket_size;
    state.total -= bucket_total;
    if (state.width > 0) {
        const bucket_mean = bucket_total / @as(f64, @floatFromInt(bucket_size));
        const difference = bucket_mean - state.total / @as(f64, @floatFromInt(state.width));
        state.variance -= state.variances[level][0] + @as(f64, @floatFromInt(bucket_size)) *
            @as(f64, @floatFromInt(state.width)) * difference * difference /
            @as(f64, @floatFromInt(bucket_size + state.width));
    } else {
        state.variance = 0.0;
    }
    if (state.variance < 0.0) state.variance = 0.0;
    removeOldest(state, level, 1);
    state.bucket_count -= 1;
}

fn detectChange(state: *Adwin) bool {
    var changed = false;
    var searching = true;
    while (searching and state.width >= 2 * MIN_SUBWINDOW) {
        searching = false;
        var stop = false;
        var old_width: i64 = 0;
        var old_total: f64 = 0.0;
        var level: i32 = @intCast(MAX_LEVELS - 1);
        while (level >= 0 and !stop) : (level -= 1) {
            const level_index: usize = @intCast(level);
            for (0..state.sizes[level_index]) |bucket| {
                if (level == 0 and bucket == state.sizes[level_index] - 1) {
                    stop = true;
                    break;
                }
                old_width += @intCast(@as(usize, 1) << @intCast(level));
                old_total += state.totals[level_index][bucket];
                const recent_width = state.width - old_width;
                const recent_total = state.total - old_total;
                if (recent_width < MIN_SUBWINDOW) {
                    stop = true;
                    break;
                }
                if (old_width >= MIN_SUBWINDOW and significant(state, old_width, recent_width,
                    old_total / @as(f64, @floatFromInt(old_width)) - recent_total / @as(f64, @floatFromInt(recent_width))))
                {
                    changed = true;
                    searching = true;
                    dropOldest(state);
                    stop = true;
                    break;
                }
            }
        }
    }
    return changed;
}

fn writeI64(output: [*]u8, word_index: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[8 * word_index + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
}

export fn adwin(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 3 or length > 2 + MAX_SAMPLES) return -1;
    const sample_count_value = input[0];
    const delta_value = input[1];
    if (sample_count_value < 1 or sample_count_value > @as(i64, @intCast(MAX_SAMPLES)) or
        length != 2 + @as(usize, @intCast(sample_count_value)) or delta_value < 1 or delta_value > 100_000_000) return -1;
    const sample_count: usize = @intCast(sample_count_value);
    for (0..sample_count) |i| {
        if (input[2 + i] < -1_000_000_000 or input[2 + i] > 1_000_000_000) return -1;
    }
    if (output_capacity < 16 * sample_count) return -2;

    var state = Adwin{ .delta = @as(f64, @floatFromInt(delta_value)) / INPUT_SCALE };
    for (0..sample_count) |i| {
        insert(&state, @as(f64, @floatFromInt(input[2 + i])) / INPUT_SCALE);
        const flag: i64 = if (detectChange(&state)) 1 else 0;
        writeI64(output, 2 * i, flag);
        writeI64(output, 2 * i + 1, state.width);
    }
    return @intCast(2 * sample_count);
}
