const MAX_INPUT_LENGTH: usize = 3 + 16 + 32 * 16;
const MAX_STATES: usize = 33;
const NEG_INF: f64 = -1.0e300;
const INVALID_RESULT: f64 = -1.0e300;

fn logaddexp_value(left: f64, right: f64) f64 {
    if (left <= NEG_INF / 2.0) return right;
    if (right <= NEG_INF / 2.0) return left;
    const larger = @max(left, right);
    const smaller = @min(left, right);
    return larger + @log(1.0 + @exp(smaller - larger));
}

export fn connectionist_temporal_classification_loss(values: [*]const i64, length: usize) f64 {
    if (length < 3 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const time_value, const classes_value, const target_value = .{ values[0], values[1], values[2] };
    if (time_value < 1 or time_value > 32 or classes_value < 2 or classes_value > 16 or target_value < 1 or target_value > 16) return INVALID_RESULT;
    const time: usize = @intCast(time_value);
    const classes: usize = @intCast(classes_value);
    const target_length: usize = @intCast(target_value);
    const probability_base = 3 + target_length;
    if (length != probability_base + time * classes) return INVALID_RESULT;
    var repeated: usize = 0;
    for (0..target_length) |i| {
        const target = values[3 + i];
        if (target < 1 or target >= classes_value) return INVALID_RESULT;
        if (i > 0 and target == values[3 + i - 1]) repeated += 1;
    }
    if (time < target_length + repeated) return INVALID_RESULT;
    for (0..time) |t| {
        var row_sum: i64 = 0;
        for (0..classes) |c| {
            const p = values[probability_base + t * classes + c];
            if (p < 1 or p > 1_000_000) return INVALID_RESULT;
            row_sum += p;
        }
        if (row_sum != 1_000_000) return INVALID_RESULT;
    }
    const states = 2 * target_length + 1;
    var extended: [MAX_STATES]i64 = @splat(0);
    var previous: [MAX_STATES]f64 = @splat(NEG_INF);
    var current: [MAX_STATES]f64 = @splat(NEG_INF);
    for (0..states) |s| extended[s] = if (s % 2 == 0) 0 else values[3 + s / 2];
    previous[0] = @log(@as(f64, @floatFromInt(values[probability_base])) / 1_000_000.0);
    previous[1] = @log(@as(f64, @floatFromInt(values[probability_base + @as(usize, @intCast(extended[1]))])) / 1_000_000.0);
    for (1..time) |t| {
        for (0..states) |s| {
            var incoming = previous[s];
            if (s > 0) incoming = logaddexp_value(incoming, previous[s - 1]);
            if (s > 1 and extended[s] != extended[s - 2]) incoming = logaddexp_value(incoming, previous[s - 2]);
            const label: usize = @intCast(extended[s]);
            const p = @as(f64, @floatFromInt(values[probability_base + t * classes + label])) / 1_000_000.0;
            current[s] = incoming + @log(p);
        }
        for (0..states) |s| previous[s] = current[s];
    }
    return -logaddexp_value(previous[states - 1], previous[states - 2]);
}
