export fn pi_approximation(points: [*]const f64, point_count: usize) f64 {
    var inside: u64 = 0;
    for (0..point_count) |index| {
        const x = points[2 * index];
        const y = points[2 * index + 1];
        if (x * x + y * y <= 1.0) inside += 1;
    }
    return 4.0 * @as(f64, @floatFromInt(inside)) /
        @as(f64, @floatFromInt(point_count));
}
