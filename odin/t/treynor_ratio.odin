package treynor_ratio

import "core:c"

@(export)
treynor_ratio :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return -1.0e300
	portfolio_return := values[0]
	risk_free_rate := values[1]
	beta := values[2]
	if portfolio_return < -1000 || portfolio_return > 1000 ||
		risk_free_rate < -1000 || risk_free_rate > 1000 ||
		beta < -1000 || beta > 1000 || beta == 0 do return -1.0e300
	return f64(portfolio_return - risk_free_rate) / f64(beta)
}
