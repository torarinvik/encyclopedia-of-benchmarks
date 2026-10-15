/// Future value of an annuity due using the pinned source formula.
export fn annuity_due_future_value(payment: f64, periods: f64, rate: f64) f64 {
    const annuity_factor = (@exp(periods * @log(1.0 + rate)) - 1.0) / rate;
    return payment * annuity_factor * (1.0 + rate);
}
