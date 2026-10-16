module gross_profit_margin

const invalid_result = -1.0e300

// Cross-platform scalar implementation of gross_profit_margin.
@[export: 'gross_profit_margin']
pub fn gross_profit_margin(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 2 { return invalid_result }
	revenue := unsafe { values[0] }
	cost := unsafe { values[1] }
	if revenue < 1 || revenue > 1000000 || cost < 0 || cost > 1000000 { return invalid_result }
	return (f64(revenue) - f64(cost)) / f64(revenue)
}
