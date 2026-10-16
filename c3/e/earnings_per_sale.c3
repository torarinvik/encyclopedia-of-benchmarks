module earnings_per_sale;

const double INVALID_RESULT = -1.0e300;

fn double earnings_per_sale(long* values, usz length) @export("earnings_per_sale") {
    if (values == null || length != 3) return INVALID_RESULT;
    long net_income = values[0];
    long preferred_dividend = values[1];
    long average_shares = values[2];
    if (net_income < -1000000 || net_income > 1000000 || preferred_dividend < 0 || preferred_dividend > 1000000 || average_shares < 1 || average_shares > 1000000) return INVALID_RESULT;
    return ((double)net_income - (double)preferred_dividend) / (double)average_shares;
}
