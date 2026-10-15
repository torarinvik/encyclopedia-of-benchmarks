module unique_occurrences

// Check whether every present value has a distinct occurrence count.
@[export: 'unique_occurrences']
pub fn unique_occurrences(values &i64, length usize) i64 {
	if length > 1000 { return -1 }
	mut counts := [2001]i64{}
	mut seen_frequencies := [1001]bool{}
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < -1000 || value > 1000 { return -1 }
		counts[int(value + 1000)]++
	}
	for frequency in counts {
		if frequency == 0 { continue }
		if seen_frequencies[int(frequency)] { return 0 }
		seen_frequencies[int(frequency)] = true
	}
	return 1
}
