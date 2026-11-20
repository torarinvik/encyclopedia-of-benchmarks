export fn liu_hui_pi_approximation(values_opt: ?[*]const i64, length: usize) i64 {
    if (values_opt == null or length != 1) return -1;
    const values = values_opt.?;
    const doublings = values[0];
    if (doublings < 0 or doublings > 16) return -1;

    var sides: i64 = 6;
    var side: f64 = 1.0;
    var apothem: f64 = @sqrt(0.75);
    var i: i64 = 0;
    while (i < doublings) : (i += 1) {
        const half_side = side / 2.0;
        const height = 1.0 - apothem;
        side = @sqrt(half_side * half_side + height * height);
        sides *= 2;
        const next_half_side = side / 2.0;
        apothem = @sqrt(1.0 - next_half_side * next_half_side);
    }

    const area = @as(f64, @floatFromInt(sides)) * side * apothem / 2.0;
    return @intFromFloat(area * 1_000_000.0 + 0.5);
}
