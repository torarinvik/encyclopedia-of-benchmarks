package units_converter

import "core:c"

MAX_UNITS :: 8
MAX_CONVERSIONS :: MAX_UNITS * MAX_UNITS
MAX_VALUE_MICRO :: i64(1_000_000_000_000)
MAX_SLOPE_PPM :: i64(5_000_000)
MAX_INTERCEPT_MICRO :: i64(1_000_000_000_000)
INVALID_RESULT :: f64(-1.0e300)

find_root :: proc(parent: [^]i64, node: i64) -> i64 {
	current := node
	for parent[current] != current {
		parent[current] = parent[parent[current]]
		current = parent[current]
	}
	return current
}

put_if_needed :: proc(present: [^]i64, slopes: [^]f64, intercepts: [^]f64,
		count: ^int, source, target: int, slope, intercept: f64) -> bool {
	if source == target do return false
	slot := source * MAX_UNITS + target
	if present[slot] != 0 do return false
	present[slot] = 1
	slopes[slot] = slope
	intercepts[slot] = intercept
	count^ += 1
	return true
}

add_all :: proc(known_present: [^]i64, known_slopes: [^]f64, known_intercepts: [^]f64,
		unit_count: i64, result_present: [^]i64, result_slopes: [^]f64,
		result_intercepts: [^]f64) -> int {
	inverse_present: [MAX_CONVERSIONS]i64 = {}
	inverse_slopes: [MAX_CONVERSIONS]f64 = {}
	inverse_intercepts: [MAX_CONVERSIONS]f64 = {}
	inverse_count := 0
	for source := i64(0); source < unit_count; source += 1 {
		for target := i64(0); target < unit_count; target += 1 {
			slot := int(source) * MAX_UNITS + int(target)
			if known_present[slot] == 0 do continue
			_ = put_if_needed(&inverse_present[0], &inverse_slopes[0], &inverse_intercepts[0],
				&inverse_count, int(source), int(target), known_slopes[slot], known_intercepts[slot])
			_ = put_if_needed(&inverse_present[0], &inverse_slopes[0], &inverse_intercepts[0],
				&inverse_count, int(target), int(source), 1.0 / known_slopes[slot],
				-known_intercepts[slot] / known_slopes[slot])
		}
	}

	result_count := 0
	for first_source := i64(0); first_source < unit_count; first_source += 1 {
		for middle := i64(0); middle < unit_count; middle += 1 {
			first_slot := int(first_source) * MAX_UNITS + int(middle)
			if inverse_present[first_slot] == 0 do continue
			_ = put_if_needed(result_present, result_slopes, result_intercepts, &result_count,
				int(first_source), int(middle), inverse_slopes[first_slot], inverse_intercepts[first_slot])
			for target := i64(0); target < unit_count; target += 1 {
				second_slot := int(middle) * MAX_UNITS + int(target)
				if inverse_present[second_slot] == 0 do continue
				_ = put_if_needed(result_present, result_slopes, result_intercepts, &result_count,
					int(first_source), int(target),
					inverse_slopes[second_slot] * inverse_slopes[first_slot],
					inverse_slopes[second_slot] * inverse_intercepts[first_slot] + inverse_intercepts[second_slot])
			}
		}
	}
	return result_count
}

@(export)
units_converter :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 4 || length > 35 do return INVALID_RESULT
	source_value, target_value, value_micro := i64(0), i64(0), i64(0)
	unit_count := i64(0)
	known_present: [MAX_CONVERSIONS]i64 = {}
	known_slopes: [MAX_CONVERSIONS]f64 = {}
	known_intercepts: [MAX_CONVERSIONS]f64 = {}
	known_count := 0

	if values[0] == 0 {
		if length != 4 do return INVALID_RESULT
		source_value, target_value, value_micro = values[1], values[2], values[3]
		unit_count = 6
		source_units := [5]int{0, 1, 3, 4, 5}
		target_units := [5]int{1, 2, 1, 1, 0}
		slopes := [5]f64{1.0, 9.0 / 5.0, 5.0 / 4.0, -2.0 / 3.0, 5.0 / 9.0}
		intercepts := [5]f64{-273.15, 32.0, 0.0, 100.0, 0.0}
		for edge in 0..<5 {
			slot := source_units[edge] * MAX_UNITS + target_units[edge]
			known_present[slot] = 1
			known_slopes[slot] = slopes[edge]
			known_intercepts[slot] = intercepts[edge]
			known_count += 1
		}
	} else if values[0] == 1 {
		if length < 6 do return INVALID_RESULT
		unit_count_value, edge_count := values[1], values[2]
		source_value, target_value, value_micro = values[3], values[4], values[5]
		if unit_count_value < 2 || unit_count_value > MAX_UNITS || edge_count < 0 ||
			edge_count > unit_count_value - 1 || length != c.size_t(6 + 4 * edge_count) do return INVALID_RESULT
		unit_count = unit_count_value
		parent: [MAX_UNITS]i64
		for unit := i64(0); unit < unit_count; unit += 1 { parent[unit] = unit }
		for edge := i64(0); edge < edge_count; edge += 1 {
			offset := int(6 + 4 * edge)
			from, to := values[offset], values[offset + 1]
			slope_ppm, intercept_micro := values[offset + 2], values[offset + 3]
			if from < 0 || from >= unit_count_value || to < 0 || to >= unit_count_value || from == to ||
				slope_ppm == 0 || slope_ppm < -MAX_SLOPE_PPM || slope_ppm > MAX_SLOPE_PPM ||
				intercept_micro < -MAX_INTERCEPT_MICRO || intercept_micro > MAX_INTERCEPT_MICRO do return INVALID_RESULT
			root_from, root_to := find_root(&parent[0], from), find_root(&parent[0], to)
			if root_from == root_to do return INVALID_RESULT
			parent[root_from] = root_to
			slot := int(from) * MAX_UNITS + int(to)
			known_present[slot] = 1
			known_slopes[slot] = f64(slope_ppm) / 1_000_000.0
			known_intercepts[slot] = f64(intercept_micro) / 1_000_000.0
			known_count += 1
		}
	} else {
		return INVALID_RESULT
	}

	if source_value < 0 || source_value >= unit_count || target_value < 0 || target_value >= unit_count ||
		source_value == target_value || value_micro < -MAX_VALUE_MICRO || value_micro > MAX_VALUE_MICRO do return INVALID_RESULT

	stable := false
	for iteration := 0; iteration <= MAX_UNITS; iteration += 1 {
		next_present: [MAX_CONVERSIONS]i64 = {}
		next_slopes: [MAX_CONVERSIONS]f64 = {}
		next_intercepts: [MAX_CONVERSIONS]f64 = {}
		next_count := add_all(&known_present[0], &known_slopes[0], &known_intercepts[0], unit_count,
			&next_present[0], &next_slopes[0], &next_intercepts[0])
		for slot in 0..<MAX_CONVERSIONS {
			known_present[slot] = next_present[slot]
			known_slopes[slot] = next_slopes[slot]
			known_intercepts[slot] = next_intercepts[slot]
		}
		if next_count == known_count { stable = true; break }
		known_count = next_count
	}
	if !stable do return INVALID_RESULT
	result_slot := int(source_value) * MAX_UNITS + int(target_value)
	if known_present[result_slot] == 0 do return INVALID_RESULT
	value := f64(value_micro) / 1_000_000.0
	return known_slopes[result_slot] * value + known_intercepts[result_slot]
}
