export fn kahan_summation(values: [*c]const f64, length: usize,
                          output: [*c]f64, capacity: usize) i64 {
    if (values == null or length > 256) return -1;
    for (0..length) |index| {
        const value = values[index];
        if (!std.math.isFinite(value) or @abs(value) > 1.0e100) return -1;
    }
    if (output == null or capacity < 1) return -2;

    var sum: f64 = 0.0;
    var correction: f64 = 0.0;
    for (0..length) |index| {
        const adjusted = values[index] - correction;
        const next = sum + adjusted;
        correction = (next - sum) - adjusted;
        sum = next;
    }
    output[0] = sum;
    return 1;
}

const std = @import("std");
