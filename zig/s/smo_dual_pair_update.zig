const std = @import("std");

const max_n: usize = 8;
const max_d: usize = 3;
const max_input: usize = 47;

fn field(x: f64, low: i64, high: i64) bool {
    return std.math.isFinite(x) and x >= @as(f64, @floatFromInt(low)) and
        x <= @as(f64, @floatFromInt(high)) and @trunc(x) == x;
}

fn dot(x: *const [max_n * max_d]f64, a: usize, b: usize, d: usize) f64 {
    var sum: f64 = 0.0;
    for (0..d) |r| sum += x.*[a * max_d + r] * x.*[b * max_d + r];
    return sum;
}

fn objective(alpha: *const [max_n]f64, labels: *const [max_n]i64,
    x: *const [max_n * max_d]f64, n: usize, d: usize) f64 {
    var sum: f64 = 0.0;
    for (0..n) |p| sum += alpha.*[p];
    for (0..n) |p| {
        for (0..n) |q| {
            sum -= 0.5 * alpha.*[p] * alpha.*[q] *
                @as(f64, @floatFromInt(labels.*[p] * labels.*[q])) * dot(x, p, q, d);
        }
    }
    return sum;
}

export fn smo_dual_pair_update(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 6 or input_length > max_input or
        !field(values[0], 2, @intCast(max_n)) or !field(values[1], 1, @intCast(max_d)) or
        !field(values[2], 1, 5000) or !field(values[3], -1_000_000, 1_000_000)) return -1;
    const n: usize = @intFromFloat(values[0]);
    const d: usize = @intFromFloat(values[1]);
    const c_milli: i64 = @intFromFloat(values[2]);
    const b_milli: i64 = @intFromFloat(values[3]);
    if (input_length != 6 + 2 * n + n * d) return -1;

    var labels: [max_n]i64 = [_]i64{0} ** max_n;
    var alpha: [max_n]f64 = [_]f64{0.0} ** max_n;
    var features: [max_n * max_d]f64 = [_]f64{0.0} ** (max_n * max_d);
    var negative = false;
    var positive = false;
    var equality: i64 = 0;
    var at: usize = 4;
    for (0..n) |k| {
        if (!field(values[at], -1, 1) or values[at] == 0.0) return -1;
        labels[k] = @intFromFloat(values[at]);
        negative = negative or labels[k] < 0;
        positive = positive or labels[k] > 0;
        at += 1;
    }
    for (0..n) |k| {
        if (!field(values[at], 0, c_milli)) return -1;
        const value: i64 = @intFromFloat(values[at]);
        alpha[k] = @as(f64, @floatFromInt(value)) / 1000.0;
        equality += labels[k] * value;
        at += 1;
    }
    if (!negative or !positive or equality != 0) return -1;
    for (0..n) |row| {
        for (0..d) |col| {
            if (!field(values[at], -32, 32)) return -1;
            features[row * max_d + col] = values[at];
            at += 1;
        }
    }
    if (!field(values[at], 0, @intCast(n - 1)) or !field(values[at + 1], 0, @intCast(n - 1))) return -1;
    const i: usize = @intFromFloat(values[at]);
    const j: usize = @intFromFloat(values[at + 1]);
    if (i == j) return -1;
    const out = output orelse return -2;
    if (output_capacity < n + 1) return -2;

    const c_value = @as(f64, @floatFromInt(c_milli)) / 1000.0;
    const bias = @as(f64, @floatFromInt(b_milli)) / 1000.0;
    const yi = labels[i];
    const yj = labels[j];
    const sign = yi * yj;
    const old_i = alpha[i];
    const old_j = alpha[j];
    const kii = dot(&features, i, i, d);
    const kjj = dot(&features, j, j, d);
    const kij = dot(&features, i, j, d);
    var error_i = bias - @as(f64, @floatFromInt(yi));
    var error_j = bias - @as(f64, @floatFromInt(yj));
    for (0..n) |k| {
        error_i += alpha[k] * @as(f64, @floatFromInt(labels[k])) * dot(&features, k, i, d);
        error_j += alpha[k] * @as(f64, @floatFromInt(labels[k])) * dot(&features, k, j, d);
    }
    var low: f64 = 0.0;
    var high: f64 = 0.0;
    if (yi != yj) {
        low = @max(0.0, old_j - old_i);
        high = @min(c_value, c_value + old_j - old_i);
    } else {
        low = @max(0.0, old_i + old_j - c_value);
        high = @min(c_value, old_i + old_j);
    }
    const eta = 2.0 * kij - kii - kjj;
    var new_j: f64 = undefined;
    if (eta < 0.0) {
        new_j = @max(low, @min(high, old_j - @as(f64, @floatFromInt(yj)) * (error_i - error_j) / eta));
    } else {
        var candidate = alpha;
        candidate[i] = old_i + @as(f64, @floatFromInt(sign)) * (old_j - low);
        candidate[j] = low;
        const low_score = objective(&candidate, &labels, &features, n, d);
        candidate[i] = old_i + @as(f64, @floatFromInt(sign)) * (old_j - high);
        candidate[j] = high;
        const high_score = objective(&candidate, &labels, &features, n, d);
        new_j = if (high_score > low_score) high else low;
    }
    const new_i = old_i + @as(f64, @floatFromInt(sign)) * (old_j - new_j);
    const delta_i = new_i - old_i;
    const delta_j = new_j - old_j;
    const yi_f = @as(f64, @floatFromInt(yi));
    const yj_f = @as(f64, @floatFromInt(yj));
    const bias_i = bias - error_i - yi_f * delta_i * kii - yj_f * delta_j * kij;
    const bias_j = bias - error_j - yi_f * delta_i * kij - yj_f * delta_j * kjj;
    const new_bias = if (new_i > 0.0 and new_i < c_value) bias_i
        else if (new_j > 0.0 and new_j < c_value) bias_j
        else 0.5 * (bias_i + bias_j);
    alpha[i] = new_i;
    alpha[j] = new_j;
    for (0..n) |k| out[k] = alpha[k];
    out[n] = new_bias;
    return @intCast(n + 1);
}
