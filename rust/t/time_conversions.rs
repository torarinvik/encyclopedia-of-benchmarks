fn seconds_factor(code: f64) -> f64 {
    match code {
        0.0 => 1.0,
        1.0 => 60.0,
        2.0 => 3600.0,
        3.0 => 86400.0,
        4.0 => 604800.0,
        5.0 => 2629800.0,
        6.0 => 31557600.0,
        _ => 0.0,
    }
}

fn inverse_factor(code: f64) -> f64 {
    match code {
        0.0 => 1.0,
        1.0 => 0.016666666666666666,
        2.0 => 0.0002777777777777778,
        3.0 => 0.000011574074074074073,
        4.0 => 0.0000016534391534391535,
        5.0 => 0.0000003802570537683474,
        6.0 => 0.00000003168808781402895,
        _ => 0.0,
    }
}

fn round_three_ties_even(value: f64) -> f64 {
    let scaled = value * 1000.0;
    let lower = scaled.floor();
    let fraction = scaled - lower;
    let residual = value.mul_add(1000.0, -scaled);
    let mut rounded = lower;
    if fraction > 0.5 || (fraction == 0.5 && (residual > 0.0 || (residual == 0.0 && (lower as i64) % 2 != 0))) {
        rounded = lower + 1.0;
    }
    rounded / 1000.0
}

#[no_mangle]
pub extern "C" fn time_conversions(time_value: f64, from_code: f64, to_code: f64) -> f64 {
    if !time_value.is_finite() || time_value < 0.0 || time_value > 10_000.0 {
        return -1e300;
    }
    let source = seconds_factor(from_code);
    let inverse = inverse_factor(to_code);
    if source == 0.0 || inverse == 0.0 {
        return -1e300;
    }
    let scaled = time_value * source;
    round_three_ties_even(scaled * inverse)
}
