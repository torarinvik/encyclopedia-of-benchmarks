module comp_filt

const max_samples = 32
const scale = i64(1_000_000)
const max_signal_micro = i64(1_000_000)
const invalid_result = -1.0e300

@[export: 'comp_filt']
pub fn comp_filt(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 6 || length > 68 { return invalid_result }
	alpha_ppm := unsafe { values[0] }
	delta_t_micro := unsafe { values[1] }
	count_value := unsafe { values[2] }
	output_index_value := unsafe { values[3] }
	if alpha_ppm < 0 || alpha_ppm > scale || delta_t_micro < 0 || delta_t_micro > scale ||
		count_value < 1 || count_value > max_samples || output_index_value < 0 || output_index_value > count_value {
		return invalid_result
	}
	count := usize(count_value)
	output_index := usize(output_index_value)
	if length != 4 + 2 * count { return invalid_result }
	for i in 0 .. count {
		rate := unsafe { values[4 + i] }
		reference := unsafe { values[4 + count + i] }
		if rate < -max_signal_micro || rate > max_signal_micro ||
			reference < -max_signal_micro || reference > max_signal_micro { return invalid_result }
	}
	alpha := f64(alpha_ppm) / f64(scale)
	delta_t := f64(delta_t_micro) / f64(scale)
	mut theta := f64(unsafe { values[4 + count] }) / f64(scale)
	for i in 0 .. output_index {
		rate := f64(unsafe { values[4 + i] }) / f64(scale)
		reference := f64(unsafe { values[4 + count + i] }) / f64(scale)
		theta = alpha * (theta + rate * delta_t) + (1.0 - alpha) * reference
	}
	return theta
}
