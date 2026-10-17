package laplace_transformation

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 68
MAX_SAMPLE_COUNT :: 64
MIN_SAMPLE_MICRO :: i64(-1_000_000)
MAX_SAMPLE_MICRO :: i64(1_000_000)
INVALID_RESULT :: -1.0e300

@(export)
laplace_transformation :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	sample_count_value, s_milli, dt_micro := input[0], input[1], input[2]
	if sample_count_value < 1 || sample_count_value > MAX_SAMPLE_COUNT do return INVALID_RESULT
	sample_count := int(sample_count_value)
	if length != c.size_t(sample_count + 3) || s_milli < 0 || s_milli > 1000 ||
		dt_micro < 1 || dt_micro > 1_000_000 do return INVALID_RESULT

	samples: [MAX_SAMPLE_COUNT]f64 = {}
	for index := 0; index < sample_count; index += 1 {
		sample := input[3 + index]
		if sample < MIN_SAMPLE_MICRO || sample > MAX_SAMPLE_MICRO do return INVALID_RESULT
		samples[index] = f64(sample) / 1_000_000.0
	}
	if sample_count == 1 do return 0.0

	s_value := f64(s_milli) / 1000.0
	delta_t := f64(dt_micro) / 1_000_000.0
	stop := f64(sample_count - 1) * delta_t
	step := stop / f64(sample_count - 1)
	integrand: [MAX_SAMPLE_COUNT]f64 = {}
	for index := 0; index < sample_count; index += 1 {
		time := if index == sample_count - 1 then stop else f64(index) * step
		integrand[index] = samples[index] * math.exp_f64(-s_value * time)
	}

	result: f64 = 0.0
	for index := 0; index + 1 < sample_count; index += 1 {
		result += (delta_t * (integrand[index] + integrand[index + 1])) / 2.0
	}
	return result
}
