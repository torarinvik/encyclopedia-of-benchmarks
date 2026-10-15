/// Pressure from the ideal gas law: n * T * R / V.
export fn ideal_gas_law(values: [*]const i64, length: usize) f64 {
    if (length != 3) return -1.0e300;
    const moles = values[0];
    const kelvin = values[1];
    const volume = values[2];
    if (moles < 0 or moles > 1000 or kelvin < 0 or kelvin > 1000 or volume < 1 or volume > 1000)
        return -1.0e300;
    return (@as(f64, @floatFromInt(moles)) * @as(f64, @floatFromInt(kelvin)) * 8.314462) / @as(f64, @floatFromInt(volume));
}
