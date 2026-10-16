module complementary_filter

const max_samples = 32
const scale = i64(1_000_000)
const max_signal_micro = i64(1_000_000)
const invalid_result = -1.0e300

@[export: 'complementary_filter']
pub fn complementary_filter(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 2 { return invalid_result }
	coefficient_ppm := unsafe { values[0] }
	sample_count_value := unsafe { values[1] }
	if coefficient_ppm < 1 || coefficient_ppm >= scale || sample_count_value < 1 || sample_count_value > max_samples { return invalid_result }
	sample_count := int(sample_count_value)
	if length != usize(2 + 3 * sample_count) { return invalid_result }
	for sample := 0; sample < sample_count; sample++ {
		rate := unsafe { values[2 + 3 * sample] }
		reference := unsafe { values[3 + 3 * sample] }
		elapsed := unsafe { values[4 + 3 * sample] }
		if rate < -max_signal_micro || rate > max_signal_micro || reference < -max_signal_micro ||
			reference > max_signal_micro || elapsed < 1 || elapsed > scale { return invalid_result }
	}
	coefficient := f64(coefficient_ppm) / f64(scale)
	mut value := 0.0
	for sample := 0; sample < sample_count; sample++ {
		rate := f64(unsafe { values[2 + 3 * sample] }) / f64(scale)
		reference := f64(unsafe { values[3 + 3 * sample] }) / f64(scale)
		elapsed := f64(unsafe { values[4 + 3 * sample] }) / f64(scale)
		if sample == 0 { value = reference }
		else { value = coefficient * (value + rate * elapsed) + (1.0 - coefficient) * reference }
	}
	return value
}
