/// Future value of an annuity due using the pinned source formula.
#[no_mangle]
pub extern "C" fn annuity_due_future_value(payment: f64, periods: f64, rate: f64) -> f64 {
    let annuity_factor = ((1.0 + rate).powf(periods) - 1.0) / rate;
    payment * annuity_factor * (1.0 + rate)
}
