const std = @import("std");

const max_input_length: usize = 6;
const max_intervals: usize = 16;
const nodes = [_]f64{
    0.9914553711208126392, 0.9491079123427585245, 0.8648644233597690728,
    0.7415311855993944399, 0.5860872354676911303, 0.4058451513773971669,
    0.2077849550078984676,
};
const kw = [_]f64{
    0.022935322010529225, 0.06309209262997855, 0.10479001032225018,
    0.14065325971552592, 0.16900472663926790, 0.19035057806478541,
    0.20443294007529889,
};
const gw = [_]f64{0.12948496616886969, 0.27970539148927667, 0.38183005050511894};

fn exactInteger(x: f64, low: f64, high: f64) bool {
    return std.math.isFinite(x) and x >= low and x <= high and @trunc(x) == x;
}

fn sample(id: i64, x: f64) f64 {
    return switch (id) {
        0 => @exp(4.0 * x),
        1 => @sin(10.0 * x),
        2 => 1.0 / (1.0 + 9.0 * x * x),
        else => blk: {
            const x2 = x * x;
            const x4 = x2 * x2;
            const x8 = x4 * x4;
            break :blk x8 * x4 * x2;
        },
    };
}

fn pairEstimate(id: i64, a: f64, b: f64) [2]f64 {
    const center = (a + b) * 0.5;
    const half = (b - a) * 0.5;
    const fc = sample(id, center);
    var ks = 0.2094821410847278280 * fc;
    var gs = 0.4179591836734693878 * fc;
    for (0..7) |i| {
        const offset = half * nodes[i];
        const pair = sample(id, center - offset) + sample(id, center + offset);
        ks += kw[i] * pair;
        if (i == 1) gs += gw[0] * pair;
        if (i == 3) gs += gw[1] * pair;
        if (i == 5) gs += gw[2] * pair;
    }
    return .{half * ks, half * gs};
}

export fn adaptive_gauss_kronrod_15_quadrature(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length != 5 or input_length > max_input_length or
        !exactInteger(values[0], 0, 3) or
        !exactInteger(values[1], -1_000_000, 1_000_000) or
        !exactInteger(values[2], -1_000_000, 1_000_000) or
        !exactInteger(values[3], 6, 8) or !exactInteger(values[4], 1, max_intervals)) return -1;
    const id: i64 = @intFromFloat(values[0]);
    const a_micro: i64 = @intFromFloat(values[1]);
    const b_micro: i64 = @intFromFloat(values[2]);
    const exponent: i64 = @intFromFloat(values[3]);
    const limit: usize = @intFromFloat(values[4]);
    if (a_micro > b_micro) return -1;
    const out = output orelse return -2;
    if (output_capacity < 1) return -2;
    const a = @as(f64, @floatFromInt(a_micro)) / 1_000_000.0;
    const b = @as(f64, @floatFromInt(b_micro)) / 1_000_000.0;
    if (a == b) { out[0] = 0.0; return 1; }
    var lefts = [_]f64{0.0} ** max_intervals;
    var rights = [_]f64{0.0} ** max_intervals;
    var estimates = [_]f64{0.0} ** max_intervals;
    var errors = [_]f64{0.0} ** max_intervals;
    const initial = pairEstimate(id, a, b);
    lefts[0] = a;
    rights[0] = b;
    estimates[0] = initial[0];
    errors[0] = @abs(initial[0] - initial[1]);
    var count: usize = 1;
    var tolerance: f64 = 1.0;
    var step: i64 = 0;
    while (step < exponent) : (step += 1) tolerance *= 0.1;
    while (true) {
        var total: f64 = 0.0;
        var error: f64 = 0.0;
        for (0..count) |i| { total += estimates[i]; error += errors[i]; }
        const scale = @max(1.0, @abs(total));
        if (error <= tolerance * scale) {
            if (!std.math.isFinite(total)) return -1;
            out[0] = total;
            return 1;
        }
        if (count >= limit) return -3;
        var best: usize = 0;
        for (1..count) |i| {
            if (errors[i] > errors[best] or (errors[i] == errors[best] and lefts[i] < lefts[best])) best = i;
        }
        const left = lefts[best];
        const right = rights[best];
        const middle = (left + right) * 0.5;
        const lhs = pairEstimate(id, left, middle);
        const rhs = pairEstimate(id, middle, right);
        lefts[best] = left;
        rights[best] = middle;
        estimates[best] = lhs[0];
        errors[best] = @abs(lhs[0] - lhs[1]);
        lefts[count] = middle;
        rights[count] = right;
        estimates[count] = rhs[0];
        errors[count] = @abs(rhs[0] - rhs[1]);
        count += 1;
    }
}
