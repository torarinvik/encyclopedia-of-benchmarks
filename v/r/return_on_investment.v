module return_on_investment

const invalid_result = -1.0e300

// Cross-platform scalar implementation of return_on_investment.
@[export: 'return_on_investment']
pub fn return_on_investment(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 2 { return invalid_result }
	gain := unsafe { values[0] }
	cost := unsafe { values[1] }
	if gain < -1000000 || gain > 1000000 || cost < 1 || cost > 1000000 { return invalid_result }
	return (f64(gain) - f64(cost)) / f64(cost)
}
