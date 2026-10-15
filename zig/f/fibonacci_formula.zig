const std = @import("std");

/// Source-ordered Binet formula, rounded to f32 then truncated to i32.
export fn fibonacci_formula(input: i64) i64 {
    if (input < 0 or input > 35) return -1;
    const n: u32 = @intCast(input);
    const exponent: f64 = @floatFromInt(n + 1);
    const seq: f32 = @floatCast((1.0 / @sqrt(@as(f64, 5.0))
        * std.math.pow(f64, (1.0 + @sqrt(@as(f64, 5.0))) / 2.0, exponent))
        - (1.0 / @sqrt(@as(f64, 5.0))
        * std.math.pow(f64, (1.0 - @sqrt(@as(f64, 5.0))) / 2.0, exponent)));
    return @as(i64, @intCast(@as(i32, @intFromFloat(seq))));
}
