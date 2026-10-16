package comp_filt

import "core:c"

MAX_SAMPLES :: 32
SCALE :: i64(1_000_000)
MAX_SIGNAL_MICRO :: i64(1_000_000)
INVALID_RESULT :: -1.0e300

@(export)
comp_filt :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 6 || length > 68 do return INVALID_RESULT
	alpha_ppm := values[0]
	delta_t_micro := values[1]
	count_value := values[2]
	output_index_value := values[3]
	if alpha_ppm < 0 || alpha_ppm > SCALE || delta_t_micro < 0 || delta_t_micro > SCALE ||
		count_value < 1 || count_value > MAX_SAMPLES || output_index_value < 0 || output_index_value > count_value do return INVALID_RESULT
	count := int(count_value)
	output_index := int(output_index_value)
	if length != c.size_t(4 + 2 * count) do return INVALID_RESULT
	for i := 0; i < count; i += 1 {
		rate := values[4 + i]
		reference := values[4 + count + i]
		if rate < -MAX_SIGNAL_MICRO || rate > MAX_SIGNAL_MICRO || reference < -MAX_SIGNAL_MICRO || reference > MAX_SIGNAL_MICRO do return INVALID_RESULT
	}
	alpha := f64(alpha_ppm) / f64(SCALE)
	delta_t := f64(delta_t_micro) / f64(SCALE)
	theta := f64(values[4 + count]) / f64(SCALE)
	for i := 0; i < output_index; i += 1 {
		rate := f64(values[4 + i]) / f64(SCALE)
		reference := f64(values[4 + count + i]) / f64(SCALE)
		theta = alpha * (theta + rate * delta_t) + (1.0 - alpha) * reference
	}
	return theta
}
