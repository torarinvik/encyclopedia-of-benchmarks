/// Ordinary annuity future value using the pinned source formula.
export fn ordinary_annuity_future_value(term_payment: f64, number_of_payments: f64, term_interest_rate: f64) f64 {
    const annuity_factor = (@exp(number_of_payments * @log(1.0 + term_interest_rate)) - 1.0) / term_interest_rate;
    return term_payment * annuity_factor;
}
