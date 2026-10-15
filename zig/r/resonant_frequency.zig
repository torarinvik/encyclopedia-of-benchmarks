/// LC resonant frequency over bounded integer-valued inputs.
export fn resonant_frequency(values: [*]const i64, length: usize) f64 {
    if (length != 2) return -1.0e300;
    const inductance = values[0];
    const capacitance = values[1];
    if (inductance < 1 or inductance > 1000 or capacitance < 1 or capacitance > 1000) return -1.0e300;
    const pi = 3.14159265358979323846;
    return 1.0 / (2.0 * pi * @sqrt(@as(f64, @floatFromInt(inductance)) * @as(f64, @floatFromInt(capacitance))));
}
