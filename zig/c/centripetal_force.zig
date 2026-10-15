/// Centripetal force: (mass * velocity^2) / radius.
export fn centripetal_force(values: [*]const i64, length: usize) f64 {
    if (length != 3) return -1.0e300;
    const mass = values[0];
    const velocity = values[1];
    const radius = values[2];
    if (mass < 0 or mass > 1000 or velocity < -1000 or velocity > 1000 or radius < 1 or radius > 1000)
        return -1.0e300;
    const velocity_squared: f64 = @floatFromInt(velocity) * @as(f64, @floatFromInt(velocity));
    return (@as(f64, @floatFromInt(mass)) * velocity_squared) / @as(f64, @floatFromInt(radius));
}
