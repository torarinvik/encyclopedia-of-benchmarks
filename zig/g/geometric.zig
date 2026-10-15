const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

/// Operation 0 tests a geometric sequence; operation 1 computes its mean.
export fn geometric(values: [*]const i64, length: usize) f64 {
    if (length < 2) return INVALID_RESULT;
    const operation = values[0];
    const count = length - 1;
    if (operation == 0) {
        if (count > 16) return INVALID_RESULT;
        for (1..length) |index| {
            if (values[index] < -100 or values[index] > 100) return INVALID_RESULT;
        }
        if (count == 1) return 1.0;
        if (values[1] == 0) return 0.0;
        const common_ratio = @as(f64, @floatFromInt(values[2])) / @as(f64, @floatFromInt(values[1]));
        for (0..count - 1) |index| {
            const current = values[index + 1];
            if (current == 0) return 0.0;
            const next = values[index + 2];
            if (@as(f64, @floatFromInt(next)) / @as(f64, @floatFromInt(current)) != common_ratio)
                return 0.0;
        }
        return 1.0;
    }
    if (operation == 1) {
        if (count > 7) return INVALID_RESULT;
        var product: i64 = 1;
        for (1..length) |index| {
            if (values[index] < 0 or values[index] > 100) return INVALID_RESULT;
            product *= values[index];
        }
        return std.math.pow(f64, @as(f64, @floatFromInt(product)), 1.0 / @as(f64, @floatFromInt(count)));
    }
    return INVALID_RESULT;
}
