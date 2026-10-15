const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

fn assignRanks(data: [*]const i64, n: usize, ranks: [*]f64) void {
    var order = [_]usize{0} ** 3;
    for (0..n) |i| order[i] = i;
    for (1..n) |i| {
        const key = order[i];
        var j = i;
        while (j > 0 and data[order[j - 1]] > data[key]) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = key;
    }
    var i: usize = 0;
    while (i < n) {
        var j = i;
        while (j < n - 1 and data[order[j + 1]] == data[order[i]]) : (j += 1) {}
        const rank = (@as(f64, @floatFromInt(i)) + @as(f64, @floatFromInt(j))) / 2.0 + 1.0;
        for (i..j + 1) |k| ranks[order[k]] = rank;
        i = j + 1;
    }
}

fn roundTenthTiesEven(value: f64) f64 {
    const scaled = value * 10.0;
    const lower = @floor(scaled);
    const fraction = scaled - lower;
    var rounded = lower;
    if (fraction > 0.5 or (fraction == 0.5 and @mod(lower, 2.0) != 0.0)) rounded = lower + 1.0;
    return rounded / 10.0;
}

export fn spearman_rank_correlation_coefficient(values: [*]const i64, length: usize) f64 {
    if (length < 5) return INVALID_RESULT;
    const n_value = values[0];
    if (n_value < 2 or n_value > 3 or length != 1 + 2 * @as(usize, @intCast(n_value))) return INVALID_RESULT;
    const n: usize = @intCast(n_value);
    const x = values + 1;
    const y = values + 1 + n;
    for (0..n) |i| {
        if (x[i] < -1000 or x[i] > 1000 or y[i] < -1000 or y[i] > 1000) return INVALID_RESULT;
    }
    var rank_x = [_]f64{0.0} ** 3;
    var rank_y = [_]f64{0.0} ** 3;
    assignRanks(x, n, &rank_x);
    assignRanks(y, n, &rank_y);
    var d_squared: f64 = 0.0;
    for (0..n) |i| {
        const difference = rank_x[i] - rank_y[i];
        d_squared += difference * difference;
    }
    const nf: f64 = @floatFromInt(n);
    const rho = 1.0 - (6.0 * d_squared) / (nf * (nf * nf - 1.0));
    return roundTenthTiesEven(rho);
}
