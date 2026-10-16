fn si_exponent(code: f64) -> i32 {
    match code {
        0.0 => 24,
        1.0 => 21,
        2.0 => 18,
        3.0 => 15,
        4.0 => 12,
        5.0 => 9,
        6.0 => 6,
        7.0 => 3,
        8.0 => 2,
        9.0 => 1,
        10.0 => -1,
        11.0 => -2,
        12.0 => -3,
        13.0 => -6,
        14.0 => -9,
        15.0 => -12,
        16.0 => -15,
        17.0 => -18,
        18.0 => -21,
        19.0 => -24,
        _ => 1000,
    }
}

fn binary_exponent(code: f64) -> i32 {
    match code {
        20.0 => 8,
        21.0 => 7,
        22.0 => 6,
        23.0 => 5,
        24.0 => 4,
        25.0 => 3,
        26.0 => 2,
        27.0 => 1,
        _ => 1000,
    }
}

#[no_mangle]
pub extern "C" fn prefix_conversions(known_amount: f64, known_code: f64, unknown_code: f64) -> f64 {
    if !known_amount.is_finite() || known_amount < -1_000_000.0 || known_amount > 1_000_000.0 {
        return -1e300;
    }
    let known_si = si_exponent(known_code);
    let unknown_si = si_exponent(unknown_code);
    if known_si != 1000 && unknown_si != 1000 {
        return known_amount * 10.0_f64.powi(known_si - unknown_si);
    }
    let known_binary = binary_exponent(known_code);
    let unknown_binary = binary_exponent(unknown_code);
    if known_binary != 1000 && unknown_binary != 1000 {
        return known_amount * 2.0_f64.powi((known_binary - unknown_binary) * 10);
    }
    -1e300
}
