const bad: f64 = -1.0e300;

fn sigmaPoints(x: f64, y: f64, p00: f64, p01: f64, p11: f64) ?[5][2]f64 {
    const l00 = @sqrt(2.0 * p00);
    if (l00 <= 0.0) return null;
    const l10 = (2.0 * p01) / l00;
    const remainder = 2.0 * p11 - l10 * l10;
    if (remainder <= 0.0) return null;
    const l11 = @sqrt(remainder);
    var points: [5][2]f64 = undefined;
    points[0] = .{ x, y };
    points[1] = .{ x + l00, y + l10 };
    points[2] = .{ x, y + l11 };
    points[3] = .{ x - l00, y - l10 };
    points[4] = .{ x, y - l11 };
    return points;
}

export fn unscented_kalman_filter(v: [*c]const i64, n: usize) f64 {
    if (v == null or n < 10 or n > 17) return bad;
    const steps = v[0];
    if (steps < 1 or steps > 8 or n != @as(usize, @intCast(9 + steps))) return bad;
    if (v[1] < -1000 or v[1] > 1000 or v[2] < -1000 or v[2] > 1000) return bad;
    if (v[3] < 500 or v[3] > 1000 or v[4] < -100 or v[4] > 100 or v[5] < 500 or v[5] > 1000) return bad;
    if (v[6] < 10 or v[6] > 50 or v[7] < 10 or v[7] > 50 or v[8] < 10 or v[8] > 100) return bad;
    for (9..n) |i| if (v[i] < -2000 or v[i] > 2000) return bad;

    const scale: f64 = 1000.0;
    var x = @as(f64, @floatFromInt(v[1])) / scale;
    var y = @as(f64, @floatFromInt(v[2])) / scale;
    var p00 = @as(f64, @floatFromInt(v[3])) / scale;
    var p01 = @as(f64, @floatFromInt(v[4])) / scale;
    var p11 = @as(f64, @floatFromInt(v[5])) / scale;
    const q0 = @as(f64, @floatFromInt(v[6])) / scale;
    const q1 = @as(f64, @floatFromInt(v[7])) / scale;
    const noise = @as(f64, @floatFromInt(v[8])) / scale;
    for (0..@as(usize, @intCast(steps))) |t| {
        const initial_points = sigmaPoints(x, y, p00, p01, p11) orelse return bad;
        var propagated: [5][2]f64 = undefined;
        for (0..5) |i| {
            const sx = initial_points[i][0];
            const sy = initial_points[i][1];
            propagated[i][0] = sx + 0.1 * sy;
            propagated[i][1] = sy + 0.05 * sx * sx;
        }
        var mean_x: f64 = 0.0;
        var mean_y: f64 = 0.0;
        for (1..5) |i| {
            mean_x += 0.25 * propagated[i][0];
            mean_y += 0.25 * propagated[i][1];
        }
        const dx0 = propagated[0][0] - mean_x;
        const dy0 = propagated[0][1] - mean_y;
        var next_p00 = 2.0 * dx0 * dx0;
        var next_p01 = 2.0 * dx0 * dy0;
        var next_p11 = 2.0 * dy0 * dy0;
        for (1..5) |i| {
            const dx = propagated[i][0] - mean_x;
            const dy = propagated[i][1] - mean_y;
            next_p00 += 0.25 * dx * dx;
            next_p01 += 0.25 * dx * dy;
            next_p11 += 0.25 * dy * dy;
        }
        x = mean_x;
        y = mean_y;
        p00 = next_p00 + q0;
        p01 = 0.5 * (next_p01 + next_p01);
        p11 = next_p11 + q1;

        const sigma = sigmaPoints(x, y, p00, p01, p11) orelse return bad;
        var mapped: [5]f64 = undefined;
        for (0..5) |i| mapped[i] = 0.05 * sigma[i][0] * sigma[i][0] + sigma[i][1];
        var expected_z: f64 = 0.0;
        for (1..5) |i| expected_z += 0.25 * mapped[i];
        var innovation = noise;
        var cross0: f64 = 0.0;
        var cross1: f64 = 0.0;
        for (0..5) |i| {
            const weight: f64 = if (i == 0) 2.0 else 0.25;
            const dx = sigma[i][0] - x;
            const dy = sigma[i][1] - y;
            const dz = mapped[i] - expected_z;
            innovation += weight * dz * dz;
            cross0 += weight * dx * dz;
            cross1 += weight * dy * dz;
        }
        if (!(innovation > 0.0)) return bad;
        const k0 = cross0 / innovation;
        const k1 = cross1 / innovation;
        const residual = @as(f64, @floatFromInt(v[9 + t])) / scale - expected_z;
        x += k0 * residual;
        y += k1 * residual;
        const u0 = k0 * innovation;
        const u1 = k1 * innovation;
        const old_p01 = p01;
        p00 -= u0 * k0;
        p01 = old_p01 - 0.5 * (u0 * k1 + u1 * k0);
        p11 -= u1 * k1;
    }
    return x;
}
