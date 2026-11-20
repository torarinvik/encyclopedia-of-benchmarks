const std = @import("std");

const max_n: usize = 8;
const max_d: usize = 3;
const max_input: usize = 37;
const tolerance: f64 = 0.001;
const epsilon: f64 = 0.001;

fn field(x: f64, low: i64, high: i64) bool {
    return std.math.isFinite(x) and x >= @as(f64, @floatFromInt(low)) and
        x <= @as(f64, @floatFromInt(high)) and @trunc(x) == x;
}

fn kernel(points: *const [max_n * max_d]f64, i: usize, j: usize, d: usize) f64 {
    var sum: f64 = 0.0;
    for (0..d) |k| sum += points.*[i * max_d + k] * points.*[j * max_d + k];
    return sum;
}

fn decision(index: usize, alpha: *const [max_n]f64, bias: f64,
    labels: *const [max_n]i64, points: *const [max_n * max_d]f64,
    n: usize, d: usize) f64 {
    var value = bias;
    for (0..n) |k| value += alpha.*[k] * @as(f64, @floatFromInt(labels.*[k])) * kernel(points, k, index, d);
    return value;
}

fn dual(alpha: *const [max_n]f64, labels: *const [max_n]i64,
    points: *const [max_n * max_d]f64, n: usize, d: usize) f64 {
    var value: f64 = 0.0;
    for (0..n) |i| value += alpha.*[i];
    for (0..n) |i| {
        for (0..n) |j| {
            value -= 0.5 * alpha.*[i] * alpha.*[j] *
                @as(f64, @floatFromInt(labels.*[i] * labels.*[j])) * kernel(points, i, j, d);
        }
    }
    return value;
}

fn takeStep(i: usize, j: usize, alpha: *[max_n]f64, bias: *f64, c: f64,
    labels: *const [max_n]i64, points: *const [max_n * max_d]f64,
    n: usize, d: usize) bool {
    if (i == j) return false;
    const yi = labels.*[i];
    const yj = labels.*[j];
    const sign = yi * yj;
    const old_i = alpha.*[i];
    const old_j = alpha.*[j];
    const error_i = decision(i, alpha, bias.*, labels, points, n, d) - @as(f64, @floatFromInt(yi));
    const error_j = decision(j, alpha, bias.*, labels, points, n, d) - @as(f64, @floatFromInt(yj));
    var low: f64 = 0.0;
    var high: f64 = 0.0;
    if (yi != yj) {
        low = @max(0.0, old_j - old_i);
        high = @min(c, c + old_j - old_i);
    } else {
        low = @max(0.0, old_i + old_j - c);
        high = @min(c, old_i + old_j);
    }
    if (low == high) return false;
    const kii = kernel(points, i, i, d);
    const kjj = kernel(points, j, j, d);
    const kij = kernel(points, i, j, d);
    const curvature = kii + kjj - 2.0 * kij;
    var next_j: f64 = undefined;
    if (curvature > 0.0) {
        next_j = @max(low, @min(high, old_j + @as(f64, @floatFromInt(yj)) * (error_i - error_j) / curvature));
    } else {
        var trial = alpha.*;
        trial[i] = old_i + @as(f64, @floatFromInt(sign)) * (old_j - low);
        trial[j] = low;
        const low_score = dual(&trial, labels, points, n, d);
        trial[i] = old_i + @as(f64, @floatFromInt(sign)) * (old_j - high);
        trial[j] = high;
        const high_score = dual(&trial, labels, points, n, d);
        if (low_score > high_score + epsilon) next_j = low
        else if (high_score > low_score + epsilon) next_j = high
        else next_j = old_j;
    }
    if (@abs(next_j - old_j) < epsilon * (next_j + old_j + epsilon)) return false;
    const next_i = old_i + @as(f64, @floatFromInt(sign)) * (old_j - next_j);
    const di = next_i - old_i;
    const dj = next_j - old_j;
    const yi_f = @as(f64, @floatFromInt(yi));
    const yj_f = @as(f64, @floatFromInt(yj));
    const bias_i = bias.* - error_i - yi_f * di * kii - yj_f * dj * kij;
    const bias_j = bias.* - error_j - yi_f * di * kij - yj_f * dj * kjj;
    if (next_i > 0.0 and next_i < c) bias.* = bias_i
    else if (next_j > 0.0 and next_j < c) bias.* = bias_j
    else bias.* = 0.5 * (bias_i + bias_j);
    alpha.*[i] = next_i;
    alpha.*[j] = next_j;
    return true;
}

fn examine(j: usize, alpha: *[max_n]f64, bias: *f64, c: f64,
    labels: *const [max_n]i64, points: *const [max_n * max_d]f64,
    n: usize, d: usize) bool {
    const error_j = decision(j, alpha, bias.*, labels, points, n, d) - @as(f64, @floatFromInt(labels.*[j]));
    const r = error_j * @as(f64, @floatFromInt(labels.*[j]));
    if (!((r < -tolerance and alpha.*[j] < c) or (r > tolerance and alpha.*[j] > 0.0))) return false;
    var free_count: usize = 0;
    var preferred: usize = 0;
    var greatest_gap: f64 = -1.0;
    for (0..n) |i| {
        if (alpha.*[i] > 0.0 and alpha.*[i] < c) {
            free_count += 1;
            const error_i = decision(i, alpha, bias.*, labels, points, n, d) - @as(f64, @floatFromInt(labels.*[i]));
            const gap = @abs(error_i - error_j);
            if (gap > greatest_gap) { greatest_gap = gap; preferred = i; }
        }
    }
    if (free_count > 1 and takeStep(preferred, j, alpha, bias, c, labels, points, n, d)) return true;
    for (0..n) |i| {
        if (alpha.*[i] > 0.0 and alpha.*[i] < c and takeStep(i, j, alpha, bias, c, labels, points, n, d)) return true;
    }
    for (0..n) |i| if (takeStep(i, j, alpha, bias, c, labels, points, n, d)) return true;
    return false;
}

export fn smo_deterministic_training(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 4 or input_length > max_input or
        !field(values[0], 2, @intCast(max_n)) or !field(values[1], 1, @intCast(max_d)) or
        !field(values[2], 1, 5000) or !field(values[3], 1, 16)) return -1;
    const n: usize = @intFromFloat(values[0]);
    const d: usize = @intFromFloat(values[1]);
    const c_milli: i64 = @intFromFloat(values[2]);
    const pass_cap: usize = @intFromFloat(values[3]);
    if (input_length != 4 + n + n * d) return -1;
    var labels: [max_n]i64 = [_]i64{0} ** max_n;
    var alpha: [max_n]f64 = [_]f64{0.0} ** max_n;
    var points: [max_n * max_d]f64 = [_]f64{0.0} ** (max_n * max_d);
    var positive = false;
    var negative = false;
    var at: usize = 4;
    for (0..n) |i| {
        if (!field(values[at], -1, 1) or values[at] == 0.0) return -1;
        labels[i] = @intFromFloat(values[at]);
        positive = positive or labels[i] > 0;
        negative = negative or labels[i] < 0;
        at += 1;
    }
    if (!positive or !negative) return -1;
    for (0..n) |i| {
        for (0..d) |k| {
            if (!field(values[at], -32, 32)) return -1;
            points[i * max_d + k] = values[at];
            at += 1;
        }
    }
    const out = output orelse return -2;
    if (output_capacity < n + 4) return -2;
    const c = @as(f64, @floatFromInt(c_milli)) / 1000.0;
    var bias: f64 = 0.0;
    var changed: usize = 0;
    var passes: usize = 0;
    var examine_all = true;
    while (passes < pass_cap and (changed > 0 or examine_all)) {
        changed = 0;
        for (0..n) |j| {
            if ((examine_all or (alpha[j] > 0.0 and alpha[j] < c)) and
                examine(j, &alpha, &bias, c, &labels, &points, n, d)) changed += 1;
        }
        passes += 1;
        if (examine_all) examine_all = false else if (changed == 0) examine_all = true;
    }
    var staged: [max_n + 4]f64 = [_]f64{0.0} ** (max_n + 4);
    staged[0] = @floatFromInt(passes);
    staged[1] = @floatFromInt(changed);
    staged[2] = if (passes < pass_cap and changed == 0 and !examine_all) 1.0 else 0.0;
    for (0..n) |i| staged[3 + i] = alpha[i];
    staged[3 + n] = bias;
    for (0..n + 4) |i| out[i] = staged[i];
    return @intCast(n + 4);
}
