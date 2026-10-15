module floor

// Floor for bounded finite binary64 inputs, correcting truncation below zero.
@[export: 'floor']
pub fn floor(value f64) f64 {
	if value < -1_000_000.0 || value > 1_000_000.0 {
		return -1.0
	}
	mut result := i64(value)
	if value < f64(result) {
		result--
	}
	return f64(result)
}
