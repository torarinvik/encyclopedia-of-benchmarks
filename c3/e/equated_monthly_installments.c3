module equated_monthly_installments;

extern fn double pow(double base, double exponent);
extern fn double floor(double value);

const double INVALID_RESULT = -1.0e300;

fn double equated_monthly_installments(double principal, double rate_per_annum, double years_to_repay) @export("equated_monthly_installments") {
    if (principal != principal || rate_per_annum != rate_per_annum || years_to_repay != years_to_repay ||
        principal <= 0.0 || principal > 1000000.0 || rate_per_annum < 0.0001 || rate_per_annum > 0.2 ||
        years_to_repay < 1.0 || years_to_repay > 30.0 || floor(years_to_repay) != years_to_repay) return INVALID_RESULT;
    double monthly_rate = rate_per_annum / 12.0;
    double payments = years_to_repay * 12.0;
    double factor = pow(1.0 + monthly_rate, payments);
    return principal * monthly_rate * factor / (factor - 1.0);
}
