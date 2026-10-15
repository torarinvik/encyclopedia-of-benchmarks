/// Gravitational potential energy: mass * standard gravity * height.
export fn potential_energy(values: [*]const i64, length: usize) f64 {
    if (length != 2) return -1.0e300;
    const mass = values[0];
    const height = values[1];
    if (mass < 0 or mass > 1000 or height < 0 or height > 1000)
        return -1.0e300;
    return (@as(f64, @floatFromInt(mass)) * 9.80665) * @as(f64, @floatFromInt(height));
}
