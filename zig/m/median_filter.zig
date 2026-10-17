const std = @import("std");

fn lowerBound(sorted: *const [16]f64, size: usize, value: f64) usize {
    var low: usize = 0;
    var high = size;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (sorted[middle] < value) low = middle + 1 else high = middle;
    }
    return low;
}

export fn median_filter(input: [*c]const f64, length: usize, output: [*c]f64, capacity: usize) i64 {
    if (input == null or length < 2 or length > 66) return -1;
    const window_value = input[0];
    const count_value = input[1];
    if (!std.math.isFinite(window_value) or @floor(window_value) != window_value or window_value < 1.0 or window_value > 16.0 or
        !std.math.isFinite(count_value) or @floor(count_value) != count_value or count_value < 0.0 or count_value > 64.0) return -1;
    const window: usize = @intFromFloat(window_value);
    const count: usize = @intFromFloat(count_value);
    if (length != 2 + count) return -1;
    var samples = [_]f64{0.0} ** 64;
    for (0..count) |index| {
        const value = input[2 + index];
        if (!std.math.isFinite(value) or value < -1_000_000.0 or value > 1_000_000.0) return -1;
        samples[index] = value;
    }
    if (output == null or capacity < count) return -2;

    var arrival = [_]f64{0.0} ** 16;
    var sorted = [_]f64{0.0} ** 16;
    var result = [_]f64{0.0} ** 64;
    var size: usize = 0;
    var oldest: usize = 0;
    for (0..count) |index| {
        const value = samples[index];
        if (size == window) {
            const position = lowerBound(&sorted, size, arrival[oldest]);
            var shift = position;
            while (shift + 1 < size) : (shift += 1) sorted[shift] = sorted[shift + 1];
            size -= 1;
        }
        const position = lowerBound(&sorted, size, value);
        var shift = size;
        while (shift > position) : (shift -= 1) sorted[shift] = sorted[shift - 1];
        sorted[position] = value;
        arrival[oldest] = value;
        oldest = (oldest + 1) % window;
        size += 1;
        const middle = size / 2;
        result[index] = if (size % 2 != 0) sorted[middle] else 0.5 * (sorted[middle - 1] + sorted[middle]);
    }
    for (0..count) |index| output[index] = result[index];
    return @intCast(count);
}
