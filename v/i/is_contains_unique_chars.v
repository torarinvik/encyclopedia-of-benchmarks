module is_contains_unique_chars

const max_length = 4096

@[export: 'is_contains_unique_chars']
pub fn is_contains_unique_chars(values &i64, length usize) i64 {
	if length > max_length { return -1 }
	if unsafe { values == nil } && length != 0 { return -1 }
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 0 || value > 127 { return -1 }
	}
	mut seen := [u64(0), u64(0)]
	for index in 0 .. int(length) {
		value := u64(unsafe { values[index] })
		word := int(value / 64)
		mask := u64(1) << u32(value % 64)
		if (seen[word] & mask) != 0 { return 0 }
		seen[word] |= mask
	}
	return 1
}
