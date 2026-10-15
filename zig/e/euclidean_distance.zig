const std = @import("std");
const MAX_DIMENSION: i64 = 128;

export fn euclidean_distance(values: [*]const i64, length: usize) f64 {
    if (length < 1) return -1.0e300;
    const dimension_value = values[0];
    if (dimension_value < 0 or dimension_value > MAX_DIMENSION) return -1.0e300;
    const dimension: usize = @intCast(dimension_value);
    if (length != 1 + 2 * dimension) return -1.0e300;
    var sum_of_squares: f64 = 0.0;
    for (0..dimension) |i| {
        const first = values[1 + i];
        const second = values[1 + dimension + i];
        if (first < -1_000_000 or first > 1_000_000 or second < -1_000_000 or second > 1_000_000)
            return -1.0e300;
        const difference = @as(f64, @floatFromInt(first)) - @as(f64, @floatFromInt(second));
        sum_of_squares += difference * difference;
    }
    return @sqrt(sum_of_squares);
}
