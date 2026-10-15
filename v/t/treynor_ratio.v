module treynor_ratio

@[export: 'treynor_ratio']
pub fn treynor_ratio(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	portfolio_return := unsafe { values[0] }
	risk_free_rate := unsafe { values[1] }
	beta := unsafe { values[2] }
	if portfolio_return < -1000 || portfolio_return > 1000 ||
		risk_free_rate < -1000 || risk_free_rate > 1000 ||
		beta < -1000 || beta > 1000 || beta == 0 { return -1.0e300 }
	return f64(portfolio_return - risk_free_rate) / f64(beta)
}
