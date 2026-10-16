module huber_loss

const scale = i64(1_000_000)
const max_pairs = i64(64)
const max_parsed_pairs = i64(65)
const max_sample = i64(1_000_000_000)
const max_delta = i64(1_000_000_000)
const max_input_length = usize(133)
const invalid_result = -1.0e300

@[export: 'huber_loss']
pub fn huber_loss(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 3 || length > max_input_length { return invalid_result }
	delta_value, true_count, pred_count := unsafe { values[0] }, unsafe { values[1] }, unsafe { values[2] }
	if delta_value < 0 || delta_value > max_delta || true_count < 0 || true_count > max_parsed_pairs ||
		pred_count < 0 || pred_count > max_parsed_pairs { return invalid_result }
	if length != usize(3 + true_count + pred_count) || true_count != pred_count ||
		pred_count == 0 || true_count > max_pairs { return invalid_result }

	count := int(true_count)
	for index in 0 .. count * 2 {
		value := unsafe { values[3 + index] }
		if value < -max_sample || value > max_sample { return invalid_result }
	}
	delta := f64(delta_value) / f64(scale)
	mut total_loss := 0.0
	for index in 0 .. count {
		true_value := f64(unsafe { values[3 + index] }) / f64(scale)
		predicted_value := f64(unsafe { values[3 + count + index] }) / f64(scale)
		mut residual := true_value - predicted_value
		if residual < 0.0 { residual = -residual }
		if residual <= delta { total_loss += 0.5 * (residual * residual) }
		else { total_loss += delta * residual - 0.5 * (delta * delta) }
	}
	return total_loss / f64(count)
}
