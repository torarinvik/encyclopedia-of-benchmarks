/// Black-Scholes European call/put price. Inputs use thousandths.
#[no_mangle]
pub extern "C" fn black_scholes_option_price(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 6 { return -1.0e300; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let (kind, spot_units, strike_units, time_units, volatility_units, rate_units) =
        (input[0], input[1], input[2], input[3], input[4], input[5]);
    if (kind != 0 && kind != 1) || !(10..=1_000_000_000).contains(&spot_units) ||
        !(10..=1_000_000_000).contains(&strike_units) || !(1..=100_000).contains(&time_units) ||
        !(1..=5_000).contains(&volatility_units) || !(-1_000..=1_000).contains(&rate_units) {
        return -1.0e300;
    }
    let spot = spot_units as f64 / 1000.0;
    let strike = strike_units as f64 / 1000.0;
    let time = time_units as f64 / 1000.0;
    let volatility = volatility_units as f64 / 1000.0;
    let rate = rate_units as f64 / 1000.0;
    let sigma_sqrt_time = volatility * time.sqrt();
    let d1 = ((spot / strike).ln() + (rate + volatility * volatility / 2.0) * time) / sigma_sqrt_time;
    let d2 = d1 - sigma_sqrt_time;
    let cdf = |x: f64| unsafe { erfc(-x / std::f64::consts::SQRT_2) * 0.5 };
    let cdf_d1 = cdf(d1);
    let cdf_d2 = cdf(d2);
    if kind == 0 { return spot * cdf_d1 - strike * (-rate * time).exp() * cdf_d2; }
    strike * (-rate * time).exp() * unsafe { erfc(d2 / std::f64::consts::SQRT_2) * 0.5 } -
        spot * unsafe { erfc(d1 / std::f64::consts::SQRT_2) * 0.5 }
}

unsafe extern "C" { fn erfc(value: f64) -> f64; }
