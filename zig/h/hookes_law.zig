/// Hooke's law restoring force: -spring_constant * displacement.
export fn hookes_law(values: [*]const i64, length: usize) f64 {
    if (length != 2) return -1.0e300;
    const spring_constant = values[0];
    const displacement = values[1];
    if (spring_constant < 1 or spring_constant > 1000 or displacement < -1000 or displacement > 1000)
        return -1.0e300;
    return (-@as(f64, @floatFromInt(spring_constant))) * @as(f64, @floatFromInt(displacement));
}
