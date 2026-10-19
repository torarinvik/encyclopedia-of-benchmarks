const MAX_N: usize = 32;
const MAX_OUTPUT_BYTES: usize = (MAX_N + 1) * 8;
const EPSILON: f64 = 2.2204460492503131e-16;

fn absValue(value: f64) f64 { return if (value < 0.0) -value else value; }

fn sturm(n: usize, diagonal: [*]const f64, offDiagonal: [*]const f64,
    beta: [*]const f64, x: f64) usize {
    var negativeCount: usize = 0;
    var q: f64 = 1.0;
    for (0..n) |i| {
        if (q != 0.0) q = (diagonal[i] - x) - beta[i] / q
        else q = (diagonal[i] - x) - absValue(offDiagonal[i]) / EPSILON;
        if (q < 0.0) negativeCount += 1;
    }
    return negativeCount;
}

fn putF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| output[offset + i] = @truncate(bits >> @intCast(8 * i));
}

fn solve(n: usize, staged: [*]u8) usize {
    var diagonal: [MAX_N]f64 = @splat(0.0);
    var offDiagonal: [MAX_N]f64 = @splat(0.0);
    var beta: [MAX_N]f64 = @splat(0.0);
    var eigenvalues: [MAX_N + 1]f64 = @splat(0.0);
    var lowerBounds: [MAX_N + 1]f64 = @splat(0.0);
    for (0..n) |i| {
        const value: f64 = @floatFromInt(i + 1);
        diagonal[i] = value * value;
        diagonal[i] = diagonal[i] * diagonal[i];
        offDiagonal[i] = @floatFromInt(i);
        beta[i] = offDiagonal[i] * offDiagonal[i];
    }
    beta[0] = 0.0;
    offDiagonal[0] = 0.0;

    const fudge: f64 = 1.01;
    var xmin = diagonal[n - 1] - fudge * absValue(offDiagonal[n - 1]);
    var xmax = diagonal[n - 1] + fudge * absValue(offDiagonal[n - 1]);
    var i = n - 1;
    while (i > 0) {
        i -= 1;
        const h = fudge * (absValue(offDiagonal[i]) + absValue(offDiagonal[i + 1]));
        if (diagonal[i] + h > xmax) xmax = diagonal[i] + h;
        if (diagonal[i] - h < xmin) xmin = diagonal[i] - h;
    }
    var eps2 = EPSILON * (if (xmin + xmax > 0.0) xmax else -xmin);
    var eps1 = EPSILON;
    if (eps1 <= 0.0) eps1 = eps2;
    eps2 = 0.5 * eps1 + 7.0 * eps2;

    var x0 = xmax;
    i = n;
    while (i > 0) {
        eigenvalues[i] = xmax;
        lowerBounds[i] = xmin;
        i -= 1;
    }
    var iterations: usize = 0;
    var k = n;
    while (k > 0) {
        var xu = xmin;
        i = k;
        while (i > 0) {
            if (xu < lowerBounds[i]) { xu = lowerBounds[i]; break; }
            i -= 1;
        }
        if (x0 > eigenvalues[k]) x0 = eigenvalues[k];
        var x1 = (xu + x0) / 2.0;
        while (x0 - xu > 2.0 * EPSILON * (absValue(xu) + absValue(x0)) + eps1) {
            iterations += 1;
            const count = sturm(n, &diagonal[0], &offDiagonal[0], &beta[0], x1);
            if (count < k) {
                if (count < 1) {
                    xu = x1;
                    lowerBounds[1] = x1;
                } else {
                    xu = x1;
                    lowerBounds[count + 1] = x1;
                    if (eigenvalues[count] > x1) eigenvalues[count] = x1;
                }
            } else x0 = x1;
            x1 = (xu + x0) / 2.0;
        }
        eigenvalues[k] = (xu + x0) / 2.0;
        k -= 1;
    }

    var used: usize = 0;
    for (2..n + 1) |index| {
        putF64Le(staged, used, eigenvalues[index]);
        used += 8;
    }
    putF64Le(staged, used, eps2);
    used += 8;
    putF64Le(staged, used, @floatFromInt(iterations));
    return used + 8;
}

pub export fn mccat_bisect(values: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (values == null or length != 1 or values[0] < 2 or values[0] > MAX_N) return -1;
    const n: usize = @intCast(values[0]);
    const required = (n + 1) * 8;
    if (output == null or capacity < required) return -2;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    const used = solve(n, &staged[0]);
    for (0..used) |index| output[index] = staged[index];
    return @intCast(used);
}
