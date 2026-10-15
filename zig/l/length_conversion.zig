/// Convert bounded lengths between millimeters, centimeters, meters, and kilometers.
fn metersPerUnit(unit: i32) f64 {
    return switch (unit) {
        0 => 0.001,
        1 => 0.01,
        2 => 1.0,
        3 => 1000.0,
        else => 0.0,
    };
}

export fn length_conversion(value: f64, from_unit_input: f64, to_unit_input: f64) f64 {
    if (value != value or value < -1_000_000.0 or value > 1_000_000.0) return -1e300;
    const from_unit: i32 = if (from_unit_input == 0.0) 0 else if (from_unit_input == 1.0) 1 else if (from_unit_input == 2.0) 2 else if (from_unit_input == 3.0) 3 else return -1e300;
    const to_unit: i32 = if (to_unit_input == 0.0) 0 else if (to_unit_input == 1.0) 1 else if (to_unit_input == 2.0) 2 else if (to_unit_input == 3.0) 3 else return -1e300;
    return (value * metersPerUnit(from_unit)) / metersPerUnit(to_unit);
}
