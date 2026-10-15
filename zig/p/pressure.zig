fn toPascalFactor(code: f64) f64 {
    if (code == 0.0) return 1.0;
    if (code == 1.0) return 1000.0;
    if (code == 2.0) return 1000000.0;
    if (code == 3.0) return 100000.0;
    if (code == 4.0) return 101325.0;
    if (code == 5.0) return 6894.757293168;
    return 0.0;
}

/// Convert pressure using Pascal as the intermediate unit.
export fn pressure(value: f64, from_unit_code: f64, to_unit_code: f64) f64 {
    if (value != value or value < -1000000.0 or value > 1000000.0) return -1.0;
    const from_factor = toPascalFactor(from_unit_code);
    const to_factor = toPascalFactor(to_unit_code);
    if (from_factor == 0.0 or to_factor == 0.0) return -1.0;
    const pascals = value * from_factor;
    return pascals / to_factor;
}
