module units_converter

const max_units = 8
const max_conversions = max_units * max_units
const max_value_micro = i64(1_000_000_000_000)
const max_slope_ppm = i64(5_000_000)
const max_intercept_micro = i64(1_000_000_000_000)
const invalid_result = -1.0e300

fn find_root(mut parent []i64, node i64) i64 {
	mut current := node
	for parent[current] != current {
		parent[current] = parent[parent[current]]
		current = parent[current]
	}
	return current
}

fn put_if_needed(mut present []i64, mut slopes []f64, mut intercepts []f64,
		mut count int, source int, target int, slope f64, intercept f64) bool {
	if source == target { return false }
	slot := source * max_units + target
	if present[slot] != 0 { return false }
	present[slot] = 1
	slopes[slot] = slope
	intercepts[slot] = intercept
	count++
	return true
}

fn add_all(known_present []i64, known_slopes []f64, known_intercepts []f64,
		unit_count int, mut result_present []i64, mut result_slopes []f64,
		mut result_intercepts []f64) int {
	mut inverse_present := []i64{len: max_conversions, init: 0}
	mut inverse_slopes := []f64{len: max_conversions, init: 0.0}
	mut inverse_intercepts := []f64{len: max_conversions, init: 0.0}
	mut inverse_count := 0
	for source := 0; source < unit_count; source++ {
		for target := 0; target < unit_count; target++ {
			slot := source * max_units + target
			if known_present[slot] == 0 { continue }
			put_if_needed(mut inverse_present, mut inverse_slopes, mut inverse_intercepts,
				mut inverse_count, source, target, known_slopes[slot], known_intercepts[slot])
			put_if_needed(mut inverse_present, mut inverse_slopes, mut inverse_intercepts,
				mut inverse_count, target, source, 1.0 / known_slopes[slot],
				-known_intercepts[slot] / known_slopes[slot])
		}
	}

	mut result_count := 0
	for first_source := 0; first_source < unit_count; first_source++ {
		for middle := 0; middle < unit_count; middle++ {
			first_slot := first_source * max_units + middle
			if inverse_present[first_slot] == 0 { continue }
			put_if_needed(mut result_present, mut result_slopes, mut result_intercepts, mut result_count,
				first_source, middle, inverse_slopes[first_slot], inverse_intercepts[first_slot])
			for target := 0; target < unit_count; target++ {
				second_slot := middle * max_units + target
				if inverse_present[second_slot] == 0 { continue }
				put_if_needed(mut result_present, mut result_slopes, mut result_intercepts, mut result_count,
					first_source, target,
					inverse_slopes[second_slot] * inverse_slopes[first_slot],
					inverse_slopes[second_slot] * inverse_intercepts[first_slot] + inverse_intercepts[second_slot])
			}
		}
	}
	return result_count
}

@[export: 'units_converter']
pub fn units_converter(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 4 || length > 35 { return invalid_result }
	mut source_value, target_value, value_micro := i64(0), i64(0), i64(0)
	mut unit_count := 0
	mut known_present := []i64{len: max_conversions, init: 0}
	mut known_slopes := []f64{len: max_conversions, init: 0.0}
	mut known_intercepts := []f64{len: max_conversions, init: 0.0}
	mut known_count := 0
	profile := unsafe { values[0] }

	if profile == 0 {
		if length != 4 { return invalid_result }
		source_value, target_value, value_micro = unsafe { values[1] }, unsafe { values[2] }, unsafe { values[3] }
		unit_count = 6
		source_units := [5]int{0, 1, 3, 4, 5}
		target_units := [5]int{1, 2, 1, 1, 0}
		slopes := [5]f64{1.0, 9.0 / 5.0, 5.0 / 4.0, -2.0 / 3.0, 5.0 / 9.0}
		intercepts := [5]f64{-273.15, 32.0, 0.0, 100.0, 0.0}
		for edge := 0; edge < 5; edge++ {
			slot := source_units[edge] * max_units + target_units[edge]
			known_present[slot] = 1
			known_slopes[slot] = slopes[edge]
			known_intercepts[slot] = intercepts[edge]
			known_count++
		}
	} else if profile == 1 {
		if length < 6 { return invalid_result }
		unit_count_value, edge_count := unsafe { values[1] }, unsafe { values[2] }
		source_value, target_value, value_micro = unsafe { values[3] }, unsafe { values[4] }, unsafe { values[5] }
		if unit_count_value < 2 || unit_count_value > max_units || edge_count < 0 ||
			edge_count > unit_count_value - 1 || length != usize(6 + 4 * edge_count) { return invalid_result }
		unit_count = int(unit_count_value)
		mut parent := []i64{len: max_units, init: 0}
		for unit := 0; unit < unit_count; unit++ { parent[unit] = i64(unit) }
		for edge := i64(0); edge < edge_count; edge++ {
			offset := int(6 + 4 * edge)
			from, to := unsafe { values[offset] }, unsafe { values[offset + 1] }
			slope_ppm, intercept_micro := unsafe { values[offset + 2] }, unsafe { values[offset + 3] }
			if from < 0 || from >= unit_count_value || to < 0 || to >= unit_count_value || from == to ||
				slope_ppm == 0 || slope_ppm < -max_slope_ppm || slope_ppm > max_slope_ppm ||
				intercept_micro < -max_intercept_micro || intercept_micro > max_intercept_micro { return invalid_result }
			root_from := find_root(mut parent, from)
			root_to := find_root(mut parent, to)
			if root_from == root_to { return invalid_result }
			parent[root_from] = root_to
			slot := int(from) * max_units + int(to)
			known_present[slot] = 1
			known_slopes[slot] = f64(slope_ppm) / 1_000_000.0
			known_intercepts[slot] = f64(intercept_micro) / 1_000_000.0
			known_count++
		}
	} else {
		return invalid_result
	}

	if source_value < 0 || source_value >= i64(unit_count) || target_value < 0 ||
		target_value >= i64(unit_count) || source_value == target_value ||
		value_micro < -max_value_micro || value_micro > max_value_micro { return invalid_result }

	mut stable := false
	for iteration := 0; iteration <= max_units; iteration++ {
		mut next_present := []i64{len: max_conversions, init: 0}
		mut next_slopes := []f64{len: max_conversions, init: 0.0}
		mut next_intercepts := []f64{len: max_conversions, init: 0.0}
		next_count := add_all(known_present, known_slopes, known_intercepts, unit_count,
			mut next_present, mut next_slopes, mut next_intercepts)
		known_present = next_present
		known_slopes = next_slopes
		known_intercepts = next_intercepts
		if next_count == known_count { stable = true; break }
		known_count = next_count
	}
	if !stable { return invalid_result }
	result_slot := int(source_value) * max_units + int(target_value)
	if known_present[result_slot] == 0 { return invalid_result }
	value := f64(value_micro) / 1_000_000.0
	return known_slopes[result_slot] * value + known_intercepts[result_slot]
}
