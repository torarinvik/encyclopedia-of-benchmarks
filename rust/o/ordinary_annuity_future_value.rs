/// Ordinary annuity future value using the pinned source formula.
#[no_mangle]
pub extern "C" fn ordinary_annuity_future_value(term_payment: f64, number_of_payments: f64, term_interest_rate: f64) -> f64 {
    let annuity_factor = ((1.0 + term_interest_rate).powf(number_of_payments) - 1.0) / term_interest_rate;
    term_payment * annuity_factor
}
