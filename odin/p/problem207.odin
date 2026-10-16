package problem207

INVALID_RESULT :: -1.0e300
MIN_PROPORTION :: 1.0e-5
MAX_PROPORTION :: 1.0
MAX_PARTITIONS :: 5_000_000

is_power_of_two :: proc(value: i64) -> bool {
	return value > 0 && (value & (value - 1)) == 0
}

@(export)
problem207 :: proc "c" (max_proportion: f64) -> f64 {
	if max_proportion != max_proportion || max_proportion < MIN_PROPORTION || max_proportion > MAX_PROPORTION do return INVALID_RESULT
	partitions := i64(0)
	perfect_partitions := i64(0)
	for partitions < MAX_PARTITIONS {
		partitions += 1
		candidate := partitions * (partitions + 1)
		if is_power_of_two(partitions + 1) do perfect_partitions += 1
		if f64(perfect_partitions) / f64(partitions) < max_proportion do return f64(candidate)
	}
	return INVALID_RESULT
}
