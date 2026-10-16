module weddles_rule

const max_panels = i64(64)
const max_step_nanounits = i64(1_000_000_000)
const max_sample_micro = i64(1_000_000)
const invalid_result = -1.0e300

@[export: 'weddles_rule']
pub fn weddles_rule(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 9 || length > 387 { return invalid_result }
	panels, step_nanounits := unsafe { values[0] }, unsafe { values[1] }
	if panels < 1 || panels > max_panels || length != usize(6 * panels + 3) ||
		step_nanounits < -max_step_nanounits || step_nanounits > max_step_nanounits { return invalid_result }

	sample_count := 6 * panels + 1
	mut weighted_sum := f64(0)
	mut index := i64(1)
	for index + 1 < sample_count {
		sample_micro := unsafe { values[index + 2] }
		if sample_micro < -max_sample_micro || sample_micro > max_sample_micro { return invalid_result }
		weight := if index % 2 == 0 && index % 3 != 0 { i64(1) }
			else if index % 2 != 0 && index % 3 != 0 { i64(5) }
			else if index % 6 == 0 { i64(2) }
			else { i64(6) }
		weighted_sum += f64(weight) * (f64(sample_micro) / 1_000_000.0)
		index++
	}
	first_micro, last_micro := unsafe { values[2] }, unsafe { values[sample_count + 1] }
	if first_micro < -max_sample_micro || first_micro > max_sample_micro ||
		last_micro < -max_sample_micro || last_micro > max_sample_micro { return invalid_result }
	step_size := f64(step_nanounits) / 1_000_000_000.0
	return 0.3 * step_size * (weighted_sum + f64(first_micro) / 1_000_000.0 + f64(last_micro) / 1_000_000.0)
}
