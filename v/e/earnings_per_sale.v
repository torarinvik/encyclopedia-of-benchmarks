module earnings_per_sale

const invalid_result = -1.0e300

// Cross-platform scalar implementation of earnings_per_sale.
@[export: 'earnings_per_sale']
pub fn earnings_per_sale(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 3 { return invalid_result }
	net_income := unsafe { values[0] }
	preferred_dividend := unsafe { values[1] }
	average_shares := unsafe { values[2] }
	if net_income < -1000000 || net_income > 1000000 || preferred_dividend < 0 || preferred_dividend > 1000000 || average_shares < 1 || average_shares > 1000000 { return invalid_result }
	return (f64(net_income) - f64(preferred_dividend)) / f64(average_shares)
}
