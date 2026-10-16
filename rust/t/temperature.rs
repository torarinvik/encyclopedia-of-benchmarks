fn valid_unit(unit: f64) -> bool {
    unit == 0.0 || unit == 1.0 || unit == 2.0 || unit == 3.0 ||
        unit == 4.0 || unit == 5.0 || unit == 6.0 || unit == 7.0
}

fn to_kelvin(value: f64, unit: f64) -> f64 {
    if unit == 0.0 { return value; }
    if unit == 1.0 { return value + 273.15; }
    if unit == 2.0 { return (value + 459.67) * 5.0 / 9.0; }
    if unit == 3.0 { return value * 5.0 / 9.0; }
    if unit == 4.0 { return 373.15 - value * 2.0 / 3.0; }
    if unit == 5.0 { return value * 100.0 / 33.0 + 273.15; }
    if unit == 6.0 { return value * 5.0 / 4.0 + 273.15; }
    (value - 7.5) * 40.0 / 21.0 + 273.15
}

fn from_kelvin(kelvin: f64, unit: f64) -> f64 {
    if unit == 0.0 { return kelvin; }
    if unit == 1.0 { return kelvin - 273.15; }
    if unit == 2.0 { return kelvin * 9.0 / 5.0 - 459.67; }
    if unit == 3.0 { return kelvin * 9.0 / 5.0; }
    if unit == 4.0 { return (373.15 - kelvin) * 3.0 / 2.0; }
    if unit == 5.0 { return (kelvin - 273.15) * 33.0 / 100.0; }
    if unit == 6.0 { return (kelvin - 273.15) * 4.0 / 5.0; }
    (kelvin - 273.15) * 21.0 / 40.0 + 7.5
}

#[no_mangle]
pub extern "C" fn temperature(value: f64, from_unit: f64, to_unit: f64) -> f64 {
    if !value.is_finite() || value < -1_000_000.0 || value > 1_000_000.0 ||
        !valid_unit(from_unit) || !valid_unit(to_unit) { return -1e300; }
    from_kelvin(to_kelvin(value, from_unit), to_unit)
}
