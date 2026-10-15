module annuity_due_future_value;

extern fn double pow(double base, double exponent);

// Future value of an annuity due using the pinned source formula.
fn double annuity_due_future_value(double payment, double periods, double rate) @export("annuity_due_future_value") {
    double annuity_factor = (pow(1.0 + rate, periods) - 1.0) / rate;
    return payment * annuity_factor * (1.0 + rate);
}
