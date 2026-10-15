module treynor_ratio;

const double INVALID_RESULT = -1.0e300;

fn double treynor_ratio(long* values, usz length) @export("treynor_ratio") {
    if (values == null || length != 3) return INVALID_RESULT;
    long portfolio_return = values[0];
    long risk_free_rate = values[1];
    long beta = values[2];
    if (portfolio_return < -1000 || portfolio_return > 1000 ||
        risk_free_rate < -1000 || risk_free_rate > 1000 ||
        beta < -1000 || beta > 1000 || beta == 0) return INVALID_RESULT;
    return (portfolio_return - risk_free_rate).f64() / beta.f64();
}
