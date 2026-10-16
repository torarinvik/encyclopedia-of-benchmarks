fn destination_factor(code: f64) -> f64 {
    match code {
        0.0 => 1.0,
        1.0 => 1000.0,
        2.0 => 1000000.0,
        3.0 => 0.001,
        4.0 => 0.0009842073,
        5.0 => 0.0011023122,
        6.0 => 2.2046244202,
        7.0 => 0.1574731728,
        8.0 => 35.273990723,
        9.0 => 5000.0,
        10.0 => 6.022136652e26,
        _ => 0.0,
    }
}

fn source_factor(code: f64) -> f64 {
    match code {
        0.0 => 1.0,
        1.0 => 0.001,
        2.0 => 0.000001,
        3.0 => 1000.0,
        4.0 => 1016.04608,
        5.0 => 907.184,
        6.0 => 0.453592,
        7.0 => 6.35029,
        8.0 => 0.0283495,
        9.0 => 0.0002,
        10.0 => 1.660540199e-27,
        _ => 0.0,
    }
}

#[no_mangle]
pub extern "C" fn weight_conversion(value: f64, from_code: f64, to_code: f64) -> f64 {
    if !value.is_finite() || value < -1_000_000.0 || value > 1_000_000.0 {
        return -1e300;
    }
    let destination = destination_factor(to_code);
    let source = source_factor(from_code);
    if destination == 0.0 || source == 0.0 {
        return -1e300;
    }
    let scaled = value * destination;
    scaled * source
}
