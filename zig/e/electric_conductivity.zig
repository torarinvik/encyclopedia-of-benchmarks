/// Solve one quantity in conductivity = electron concentration * mobility * charge.
export fn electric_conductivity(values: [*]const i64, length: usize) f64 {
    if (length != 3) return -1.0e300;
    const conductivity = values[0];
    const electron_conc = values[1];
    const mobility = values[2];
    if (conductivity < 0 or conductivity > 1000 or electron_conc < 0 or electron_conc > 1000 or mobility < 0 or mobility > 1000)
        return -1.0e300;
    const zeros: u8 = @intFromBool(conductivity == 0) + @intFromBool(electron_conc == 0) + @intFromBool(mobility == 0);
    if (zeros != 1) return -1.0e300;
    const charge = 1.6021e-19;
    if (conductivity == 0) return @as(f64, @floatFromInt(mobility)) * @as(f64, @floatFromInt(electron_conc)) * charge;
    if (electron_conc == 0) return @as(f64, @floatFromInt(conductivity)) / (@as(f64, @floatFromInt(mobility)) * charge);
    return @as(f64, @floatFromInt(conductivity)) / (@as(f64, @floatFromInt(electron_conc)) * charge);
}
