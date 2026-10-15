module longest_substring_without_repeating_characters

const max_length = 1024
const alphabet_size = 95

// Return the longest printable-ASCII substring with no repeated byte.
@[export: 'longest_substring_without_repeating_characters']
pub fn longest_substring_without_repeating_characters(values &i64, length usize) i64 {
	if length > max_length { return -2 }
	mut last_seen := [alphabet_size]i64{init: -1}
	mut window_start := usize(0)
	mut longest := usize(0)
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < 32 || value > 126 { return -2 }
		slot := usize(value - 32)
		previous := last_seen[slot]
		if previous >= 0 && usize(previous) >= window_start { window_start = usize(previous) + 1 }
		last_seen[slot] = i64(index)
		current := index - window_start + 1
		if current > longest { longest = current }
	}
	return i64(longest)
}
