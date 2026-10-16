/// Interquartile range using the source lower/upper-half median rule.
const INVALID_RESULT: f64 = -1.0e300;

fn median_i64(values: [*]const i64, count: usize) f64 {
    if (count % 2 != 0) return @floatFromInt(values[count / 2]);
    return (@as(f64, @floatFromInt(values[count / 2 - 1])) + @as(f64, @floatFromInt(values[count / 2]))) / 2.0;
}

export fn interquartile_range(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 2 or length > 64) return INVALID_RESULT;
    var sorted: [64]i64 = @splat(0);
    for (0..length) |i| {
        if (values[i] < -1_000_000 or values[i] > 1_000_000) return INVALID_RESULT;
        sorted[i] = values[i];
    }
    for (1..length) |i| {
        const key = sorted[i];
        var j = i;
        while (j > 0 and sorted[j - 1] > key) { sorted[j] = sorted[j - 1]; j -= 1; }
        sorted[j] = key;
    }
    const half = length / 2;
    const upper_start = half + length % 2;
    return median_i64(@ptrCast(&sorted[upper_start]), half) - median_i64(@ptrCast(&sorted[0]), half);
}
