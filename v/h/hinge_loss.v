const max_count = 256
const max_input_length = 1 + 2 * max_count
const prediction_scale = 1_000_000.0
const invalid_result = -1.0e300

@[export: 'hinge_loss']
pub fn hinge_loss(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 3 || length > max_input_length { return invalid_result }
	unsafe {
		count_value := values[0]
		if count_value < 1 || count_value > max_count { return invalid_result }
		count := int(count_value)
		if length != 1 + 2 * count { return invalid_result }

		mut total := 0.0
		for index in 0 .. count {
			label := values[1 + index]
			score_scaled := values[1 + count + index]
			if (label != -1 && label != 1) || score_scaled < -1_000_000 || score_scaled > 1_000_000 { return invalid_result }
			prediction := f64(score_scaled) / prediction_scale
			loss := 1.0 - f64(label) * prediction
			if loss > 0.0 { total += loss }
		}
		return total / f64(count)
	}
}
