fn factor(code: f64) -> f64 {
    match code {
        0.0 => 1.0,
        1.0 => 1000.0,
        2.0 => 1000000.0,
        3.0 => 1000000000.0,
        4.0 => 1.0,
        5.0 => 3600.0,
        6.0 => 3600000.0,
        7.0 => 1.0,
        8.0 => 4186.8,
        9.0 => 4186800.0,
        10.0 => 1.602176634e-19,
        11.0 => 1055.05585,
        12.0 => 1.355818,
        _ => 0.0,
    }
}

#[no_mangle]
pub extern "C" fn energy_conversions(value: f64, from_code: f64, to_code: f64) -> f64 {
    if !value.is_finite() || value < -1_000_000.0 || value > 1_000_000.0 {
        return -1e300;
    }
    let source = factor(from_code);
    let target = factor(to_code);
    if source == 0.0 || target == 0.0 {
        return -1e300;
    }
    let scaled = value * source;
    scaled / target
}
