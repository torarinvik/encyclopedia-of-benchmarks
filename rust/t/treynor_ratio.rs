/// Treynor ratio: (portfolio return - risk-free rate) / beta.
#[no_mangle]
pub extern "C" fn treynor_ratio(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return -1.0e300; }
    let portfolio_return = unsafe { *values };
    let risk_free_rate = unsafe { *values.add(1) };
    let beta = unsafe { *values.add(2) };
    if !(-1000..=1000).contains(&portfolio_return)
        || !(-1000..=1000).contains(&risk_free_rate)
        || !(-1000..=1000).contains(&beta)
        || beta == 0
    {
        return -1.0e300;
    }
    ((portfolio_return - risk_free_rate) as f64) / (beta as f64)
}
