const max_samples = 8;
const max_output = 12;

export fn pca(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, capacity: usize) i64 {
    if (input == null or input_length < 9 or input_length > 19) return -1;
    const values = input.?;
    if (values[1] != 2.0 or values[2] != 1.0) return -1;
    if (values[0] != 3.0 and values[0] != 4.0 and values[0] != 5.0 and values[0] != 6.0 and values[0] != 7.0 and values[0] != 8.0) return -1;
    const n: usize = @intFromFloat(values[0]);
    if (input_length != 3 + 2 * n) return -1;
    var x = [_]f64{0} ** max_samples;
    var y = [_]f64{0} ** max_samples;
    var z0 = [_]f64{0} ** max_samples;
    var z1 = [_]f64{0} ** max_samples;
    var mean0: f64 = 0;
    var mean1: f64 = 0;
    for (0..n) |i| {
        x[i] = values[3 + 2 * i];
        y[i] = values[4 + 2 * i];
        if (x[i] != x[i] or y[i] != y[i] or @abs(x[i]) > 1000.0 or @abs(y[i]) > 1000.0) return -1;
        mean0 += x[i];
        mean1 += y[i];
    }
    mean0 /= @as(f64, @floatFromInt(n));
    mean1 /= @as(f64, @floatFromInt(n));
    var sum0: f64 = 0;
    var sum1: f64 = 0;
    for (0..n) |i| {
        const dx = x[i] - mean0;
        const dy = y[i] - mean1;
        sum0 += dx * dx;
        sum1 += dy * dy;
    }
    const denom = @as(f64, @floatFromInt(n - 1));
    if (sum0 <= 0 or sum1 <= 0) return -1;
    const scale0 = @sqrt(sum0 / denom);
    const scale1 = @sqrt(sum1 / denom);
    var a: f64 = 0;
    var b: f64 = 0;
    var d: f64 = 0;
    for (0..n) |i| {
        z0[i] = (x[i] - mean0) / scale0;
        z1[i] = (y[i] - mean1) / scale1;
        a += z0[i] * z0[i];
        b += z0[i] * z1[i];
        d += z1[i] * z1[i];
    }
    a /= denom;
    b /= denom;
    d /= denom;
    const root = @sqrt((a - d) * (a - d) + 4 * b * b);
    const lambda0 = 0.5 * (a + d + root);
    const lambda1 = 0.5 * (a + d - root);
    if (lambda0 - lambda1 <= 1e-8) return -1;
    var vx: f64 = 0;
    var vy: f64 = 0;
    if (b == 0) {
        if (a >= d) {
            vx = 1;
        } else {
            vy = 1;
        }
    } else {
        vx = b;
        vy = lambda0 - a;
        const norm = @sqrt(vx * vx + vy * vy);
        if (norm == 0) return -1;
        vx /= norm;
        vy /= norm;
    }
    const abs_vx = @abs(vx);
    const abs_vy = @abs(vy);
    if ((abs_vx >= abs_vy and vx < 0) or (abs_vy > abs_vx and vy < 0)) {
        vx = -vx;
        vy = -vy;
    }
    var staged = [_]f64{0} ** max_output;
    for (0..n) |i| staged[i] = z0[i] * vx + z1[i] * vy;
    staged[n] = vx;
    staged[n + 1] = vy;
    staged[n + 2] = lambda0;
    staged[n + 3] = lambda1;
    const output_size = n + 4;
    const out = output orelse return -2;
    if (capacity < output_size) return -2;
    @memcpy(out[0..output_size], staged[0..output_size]);
    return @intCast(output_size);
}
