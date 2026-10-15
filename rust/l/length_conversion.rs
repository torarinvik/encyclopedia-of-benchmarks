/// Convert bounded lengths between millimeters, centimeters, meters, and kilometers.
fn meters_per_unit(unit: i32) -> f64 {
    match unit {
        0 => 0.001,
        1 => 0.01,
        2 => 1.0,
        _ => 1000.0,
    }
}

#[no_mangle]
pub extern "C" fn length_conversion(value: f64, from_unit_input: f64, to_unit_input: f64) -> f64 {
    if value.is_nan() || value < -1_000_000.0 || value > 1_000_000.0 {
        return -1e300;
    }
    let from_unit = if from_unit_input == 0.0 { 0 } else if from_unit_input == 1.0 { 1 } else if from_unit_input == 2.0 { 2 } else if from_unit_input == 3.0 { 3 } else { return -1e300; };
    let to_unit = if to_unit_input == 0.0 { 0 } else if to_unit_input == 1.0 { 1 } else if to_unit_input == 2.0 { 2 } else if to_unit_input == 3.0 { 3 } else { return -1e300; };
    (value * meters_per_unit(from_unit)) / meters_per_unit(to_unit)
}
