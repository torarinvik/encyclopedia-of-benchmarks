module debt_to_equity

const invalid_result = -1.0e300

// Cross-platform scalar implementation of debt_to_equity.
@[export: 'debt_to_equity']
pub fn debt_to_equity(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 2 { return invalid_result }
	debt := unsafe { values[0] }
	equity := unsafe { values[1] }
	if debt < 0 || debt > 1000000 || equity < 1 || equity > 1000000 { return invalid_result }
	return f64(debt) / f64(equity)
}
