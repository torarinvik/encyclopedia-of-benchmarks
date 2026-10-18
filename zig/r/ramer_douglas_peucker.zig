const std = @import("std");
const MAX_POINTS: usize = 12;
const MAX_OUTPUT: usize = 25;

extern "c" fn hypot(x: f64, y: f64) f64;

export fn ramer_douglas_peucker(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 2 or input_length > 26) return -1;
    const count_value = values[0];
    const epsilon = values[1];
    if (!std.math.isFinite(count_value) or @trunc(count_value) != count_value or count_value < 0 or count_value > 12) return -1;
    const n: usize = @intFromFloat(count_value);
    if (input_length != 2 + 2 * n or !std.math.isFinite(epsilon) or epsilon < 0 or epsilon > 100) return -1;
    var xs = [_]f64{0} ** MAX_POINTS;
    var ys = [_]f64{0} ** MAX_POINTS;
    for (0..n) |i| {
        xs[i] = values[2 + 2 * i];
        ys[i] = values[3 + 2 * i];
        if (!std.math.isFinite(xs[i]) or !std.math.isFinite(ys[i]) or @abs(xs[i]) > 100 or @abs(ys[i]) > 100) return -1;
    }
    if (n >= 3) {
        for (0..n) |i| {
            for (i + 1..n) |j| {
                if (xs[i] == xs[j] and ys[i] == ys[j]) return -1;
                const dx = xs[j] - xs[i];
                const dy = ys[j] - ys[i];
                const length_squared = dx * dx + dy * dy;
                const line_length = @sqrt(length_squared);
                if (!std.math.isFinite(length_squared) or length_squared <= 0 or !std.math.isFinite(line_length) or line_length <= 0) return -1;
                var max_clamped: f64 = 0;
                var max_line: f64 = 0;
                var index_clamped = i;
                var index_line = i;
                for (i + 1..j) |k| {
                    const px = xs[k];
                    const py = ys[k];
                    const t = ((px - xs[i]) * dx + (py - ys[i]) * dy) / length_squared;
                    if (t < 0 or t > 1) return -1;
                    const nearest_x = xs[i] + t * dx;
                    const nearest_y = ys[i] + t * dy;
                    const ddx = px - nearest_x;
                    const ddy = py - nearest_y;
                    const clamped_distance = hypot(ddx, ddy);
                    const numerator = dy * px - dx * py + xs[j] * ys[i] - ys[j] * xs[i];
                    const line_distance = @abs(numerator) / line_length;
                    if (!std.math.isFinite(clamped_distance) or !std.math.isFinite(line_distance)) return -1;
                    if (clamped_distance > max_clamped) {
                        max_clamped = clamped_distance;
                        index_clamped = k;
                    }
                    if (line_distance > max_line) {
                        max_line = line_distance;
                        index_line = k;
                    }
                }
                if (index_clamped != index_line or (max_clamped > epsilon) != (max_line > epsilon)) return -1;
            }
        }
    }
    var keep = [_]bool{false} ** MAX_POINTS;
    if (n > 0) keep[0] = true;
    if (n > 1) keep[n - 1] = true;
    if (n >= 3) {
        var starts = [_]usize{0} ** 24;
        var finishes = [_]usize{0} ** 24;
        var top: usize = 1;
        starts[0] = 0;
        finishes[0] = n - 1;
        while (top > 0) {
            top -= 1;
            const start = starts[top];
            const finish = finishes[top];
            const dx = xs[finish] - xs[start];
            const dy = ys[finish] - ys[start];
            const length_squared = dx * dx + dy * dy;
            var max_distance: f64 = 0;
            var max_index = start;
            for (start + 1..finish) |k| {
                const t = ((xs[k] - xs[start]) * dx + (ys[k] - ys[start]) * dy) / length_squared;
                const nearest_x = xs[start] + t * dx;
                const nearest_y = ys[start] + t * dy;
                const ddx = xs[k] - nearest_x;
                const ddy = ys[k] - nearest_y;
                const distance = hypot(ddx, ddy);
                if (distance > max_distance) {
                    max_distance = distance;
                    max_index = k;
                }
            }
            if (max_distance > epsilon) {
                keep[max_index] = true;
                starts[top] = start;
                finishes[top] = max_index;
                top += 1;
                starts[top] = max_index;
                finishes[top] = finish;
                top += 1;
            }
        }
    }
    var staged = [_]f64{0} ** MAX_OUTPUT;
    var result_count: usize = 0;
    for (0..n) |i| {
        if (keep[i]) {
            staged[1 + 2 * result_count] = xs[i];
            staged[2 + 2 * result_count] = ys[i];
            result_count += 1;
        }
    }
    staged[0] = @floatFromInt(result_count);
    const output_size = 1 + 2 * result_count;
    const out = output orelse return -2;
    if (capacity < output_size) return -2;
    @memcpy(out[0..output_size], staged[0..output_size]);
    return @intCast(output_size);
}
