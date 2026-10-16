package weddles_rule

import "core:c"

MAX_PANELS :: i64(64)
MAX_STEP_NANOUNITS :: i64(1_000_000_000)
MAX_SAMPLE_MICRO :: i64(1_000_000)
INVALID_RESULT :: f64(-1.0e300)

@(export)
weddles_rule :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 9 || length > 387 do return INVALID_RESULT
	panels, step_nanounits := values[0], values[1]
	if panels < 1 || panels > MAX_PANELS || length != c.size_t(6 * panels + 3) ||
		step_nanounits < -MAX_STEP_NANOUNITS || step_nanounits > MAX_STEP_NANOUNITS do return INVALID_RESULT

	sample_count := 6 * panels + 1
	weighted_sum := f64(0)
	for index: i64 = 1; index + 1 < sample_count; index += 1 {
		sample_micro := values[index + 2]
		if sample_micro < -MAX_SAMPLE_MICRO || sample_micro > MAX_SAMPLE_MICRO do return INVALID_RESULT
		weight: i64
		if index % 2 == 0 && index % 3 != 0 do weight = 1
		else if index % 2 != 0 && index % 3 != 0 do weight = 5
		else if index % 6 == 0 do weight = 2
		else do weight = 6
		weighted_sum += f64(weight) * (f64(sample_micro) / 1_000_000.0)
	}
	first_micro, last_micro := values[2], values[sample_count + 1]
	if first_micro < -MAX_SAMPLE_MICRO || first_micro > MAX_SAMPLE_MICRO ||
		last_micro < -MAX_SAMPLE_MICRO || last_micro > MAX_SAMPLE_MICRO do return INVALID_RESULT
	step_size := f64(step_nanounits) / 1_000_000_000.0
	return 0.3 * step_size * (weighted_sum + f64(first_micro) / 1_000_000.0 + f64(last_micro) / 1_000_000.0)
}
