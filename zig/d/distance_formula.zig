/// Compute the Euclidean distance with the pinned Java coordinate expression.
export fn distance_formula(values: [*]const i64, length: usize) f64 {
    if (length != 4) return -1.0e300;
    for (0..4) |i| {
        if (values[i] < -1_000_000 or values[i] > 1_000_000) return -1.0e300;
    }
    const dx: f64 = @floatFromInt(values[2] - values[0]);
    const dy: f64 = @floatFromInt(values[3] - values[0]);
    return @sqrt(dx * dx + dy * dy);
}
