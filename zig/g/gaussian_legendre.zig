const INVALID_RESULT: f64 = -1.0e300;

/// Bounded Gauss-Legendre quadrature using the pinned Fortran tables.
export fn gaussian_legendre(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 7) return INVALID_RESULT;
    if (values[0] < 1 or values[0] > 5 or values[1] < -5000 or values[1] > 5000 or
        values[2] < -5000 or values[2] > 5000) return INVALID_RESULT;
    for (3..7) |index| {
        if (values[index] < -10000 or values[index] > 10000) return INVALID_RESULT;
    }
    const order: usize = @intCast(values[0]);
    var nodes = [_]f64{ 0.0, 0.0, 0.0, 0.0, 0.0 };
    var weights = [_]f64{ 0.0, 0.0, 0.0, 0.0, 0.0 };
    switch (order) {
        1 => { nodes[0] = 0.0; weights[0] = 2.0; },
        2 => {
            nodes[0] = -0.5773502692; nodes[1] = 0.5773502692;
            weights[0] = 1.0; weights[1] = 1.0;
        },
        3 => {
            nodes[0] = -0.7745966692; nodes[1] = 0.0; nodes[2] = 0.7745966692;
            weights[0] = 0.5555555556; weights[1] = 0.8888888889; weights[2] = 0.5555555556;
        },
        4 => {
            nodes[0] = -0.8611363116; nodes[1] = -0.3399810436;
            nodes[2] = 0.3399810436; nodes[3] = 0.8611363116;
            weights[0] = 0.3478548451; weights[1] = 0.6521451549;
            weights[2] = 0.6521451549; weights[3] = 0.3478548451;
        },
        5 => {
            nodes[0] = -0.9061798459; nodes[1] = -0.5384693101; nodes[2] = 0.0;
            nodes[3] = 0.5384693101; nodes[4] = 0.9061798459;
            weights[0] = 0.2369268851; weights[1] = 0.4786286705;
            weights[2] = 0.5688888889; weights[3] = 0.4786286705; weights[4] = 0.2369268851;
        },
        else => unreachable,
    }

    const a: f64 = @as(f64, @floatFromInt(values[1])) / 1000.0;
    const b: f64 = @as(f64, @floatFromInt(values[2])) / 1000.0;
    const c0: f64 = @as(f64, @floatFromInt(values[3])) / 1000.0;
    const c1: f64 = @as(f64, @floatFromInt(values[4])) / 1000.0;
    const c2: f64 = @as(f64, @floatFromInt(values[5])) / 1000.0;
    const c3: f64 = @as(f64, @floatFromInt(values[6])) / 1000.0;
    var weighted_sum: f64 = 0.0;
    for (0..order) |index| {
        const x = (b + a) / 2.0 + (b - a) * nodes[index] / 2.0;
        const x2 = x * x;
        const x3 = x2 * x;
        const function_value = c0 + c1 * x + c2 * x2 + c3 * x3;
        weighted_sum += weights[index] * function_value;
    }
    return weighted_sum * (b - a) / 2.0;
}
