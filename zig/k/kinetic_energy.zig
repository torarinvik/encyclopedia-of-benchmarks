/// Classical kinetic energy: 0.5 * mass * abs(velocity)^2.
export fn kinetic_energy(values: [*]const i64, length: usize) f64 {
    if (length != 2) return -1.0e300;
    const mass = values[0];
    const velocity = values[1];
    if (mass < 0 or mass > 1000 or velocity < -1000 or velocity > 1000)
        return -1.0e300;
    const speed = if (velocity < 0) -velocity else velocity;
    return ((0.5 * @as(f64, @floatFromInt(mass))) * @as(f64, @floatFromInt(speed))) * @as(f64, @floatFromInt(speed));
}
