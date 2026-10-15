/// Solve impedance, resistance, or reactance from the other two values.
export fn electrical_impedance(values: [*]const i64, length: usize) f64 {
    if (length != 3) return -1.0e300;
    const resistance = values[0];
    const reactance = values[1];
    const impedance = values[2];
    if (resistance < 0 or resistance > 1000 or reactance < 0 or reactance > 1000 or impedance < 0 or impedance > 1000)
        return -1.0e300;
    const zeros: u8 = @intFromBool(resistance == 0) + @intFromBool(reactance == 0) + @intFromBool(impedance == 0);
    if (zeros != 1) return -1.0e300;
    const r: f64 = @floatFromInt(resistance);
    const x: f64 = @floatFromInt(reactance);
    const z: f64 = @floatFromInt(impedance);
    const radicand = if (resistance == 0) z * z - x * x
                     else if (reactance == 0) z * z - r * r
                     else r * r + x * x;
    if (radicand < 0.0) return -1.0e300;
    return @sqrt(radicand);
}
