/// Inductive reactance relation over a bounded integer-valued domain.
export fn ind_reactance(values: [*]const i64, length: usize) f64 {
    if (length != 3) return -1.0e300;
    const inductance = values[0];
    const frequency = values[1];
    const reactance = values[2];
    if (inductance < 0 or inductance > 1000 or frequency < 0 or frequency > 1000 or reactance < 0 or reactance > 1000)
        return -1.0e300;
    const zeros: u8 = @intFromBool(inductance == 0) + @intFromBool(frequency == 0) + @intFromBool(reactance == 0);
    if (zeros != 1) return -1.0e300;
    const pi = 3.14159265358979323846;
    if (inductance == 0) return @as(f64, @floatFromInt(reactance)) / (2.0 * pi * @as(f64, @floatFromInt(frequency)));
    if (frequency == 0) return @as(f64, @floatFromInt(reactance)) / (2.0 * pi * @as(f64, @floatFromInt(inductance)));
    return 2.0 * pi * @as(f64, @floatFromInt(frequency)) * @as(f64, @floatFromInt(inductance));
}
