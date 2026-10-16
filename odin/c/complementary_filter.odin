package complementary_filter

import "core:c"

MAX_SAMPLES :: 32
SCALE :: i64(1_000_000)
MAX_SIGNAL_MICRO :: i64(1_000_000)
INVALID_RESULT :: -1.0e300

@(export)
complementary_filter :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 2 do return INVALID_RESULT
	coefficient_ppm := values[0]
	sample_count_value := values[1]
	if coefficient_ppm < 1 || coefficient_ppm >= SCALE || sample_count_value < 1 || sample_count_value > MAX_SAMPLES do return INVALID_RESULT
	sample_count := int(sample_count_value)
	if length != c.size_t(2 + 3 * sample_count) do return INVALID_RESULT
	for sample := 0; sample < sample_count; sample += 1 {
		rate := values[2 + 3 * sample]
		reference := values[3 + 3 * sample]
		elapsed := values[4 + 3 * sample]
		if rate < -MAX_SIGNAL_MICRO || rate > MAX_SIGNAL_MICRO || reference < -MAX_SIGNAL_MICRO ||
			reference > MAX_SIGNAL_MICRO || elapsed < 1 || elapsed > SCALE do return INVALID_RESULT
	}
	coefficient := f64(coefficient_ppm) / f64(SCALE)
	value := 0.0
	for sample := 0; sample < sample_count; sample += 1 {
		rate := f64(values[2 + 3 * sample]) / f64(SCALE)
		reference := f64(values[3 + 3 * sample]) / f64(SCALE)
		elapsed := f64(values[4 + 3 * sample]) / f64(SCALE)
		if sample == 0 do value = reference
		else value = coefficient * (value + rate * elapsed) + (1.0 - coefficient) * reference
	}
	return value
}
