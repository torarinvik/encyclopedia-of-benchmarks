const std = @import("std");

const pi_value: f64 = 3.14159265358979323846264338327950288;
const tau_value: f64 = 6.28318530717958647692528676655900576;
const cutoff_scale: f64 = 0.0000000037252902984619140625;

fn wrapAngle(angle: f64) f64 {
    var value = angle - @floor((angle + pi_value) / tau_value) * tau_value;
    if (value >= pi_value) value -= tau_value;
    if (value < -pi_value) value += tau_value;
    return value;
}

export fn circular_mean_direction(input_opt: ?[*]const f64, length: usize,
        output_opt: ?[*]f64, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > 66) return -1;
    const count_value = input[0];
    if (!std.math.isFinite(count_value) or @trunc(count_value) != count_value or
        count_value < 1.0 or count_value > 64.0) return -1;
    const count: usize = @intFromFloat(count_value);
    if (length != count + 1) return -1;

    var sum_cos: f64 = 0.0;
    var sum_sin: f64 = 0.0;
    var correction_cos: f64 = 0.0;
    var correction_sin: f64 = 0.0;
    for (0..count) |index| {
        const raw = input[index + 1];
        if (!std.math.isFinite(raw) or @abs(raw) > 8.0 * pi_value) return -1;
        const angle = wrapAngle(raw);
        const adjusted_cos = @cos(angle) - correction_cos;
        const next_cos = sum_cos + adjusted_cos;
        correction_cos = (next_cos - sum_cos) - adjusted_cos;
        sum_cos = next_cos;
        const adjusted_sin = @sin(angle) - correction_sin;
        const next_sin = sum_sin + adjusted_sin;
        correction_sin = (next_sin - sum_sin) - adjusted_sin;
        sum_sin = next_sin;
    }
    const resultant = @sqrt(sum_cos * sum_cos + sum_sin * sum_sin);
    if (!std.math.isFinite(resultant) or resultant <= @as(f64, @floatFromInt(count)) * cutoff_scale) return -1;
    const output = output_opt orelse return -2;
    if (capacity < 1) return -2;
    output[0] = wrapAngle(@atan2(sum_sin, sum_cos));
    return 1;
}
