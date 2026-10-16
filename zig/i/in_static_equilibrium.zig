const INVALID_RESULT: i64 = -1;

export fn in_static_equilibrium(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 5) return INVALID_RESULT;
    const n_value = values[0];
    if (n_value < 1 or n_value > 100 or length != 1 + 4 * @as(usize, @intCast(n_value))) return INVALID_RESULT;
    const n: usize = @intCast(n_value);
    var total_moment: i64 = 0;
    for (0..n) |i| {
        const fx, fy = .{ values[1 + i], values[1 + n + i] };
        const lx, ly = .{ values[1 + 2 * n + i], values[1 + 3 * n + i] };
        if (fx < -1000 or fx > 1000 or fy < -1000 or fy > 1000 or lx < -1000 or lx > 1000 or ly < -1000 or ly > 1000) return INVALID_RESULT;
        total_moment += lx * fy - ly * fx;
    }
    return if (total_moment == 0) 1 else 0;
}
