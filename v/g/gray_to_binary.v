module gray_to_binary

// Convert a nonnegative reflected Gray-code integer to its binary integer.
@[export: 'gray_to_binary']
pub fn gray_to_binary(gray i64) i64 {
	if gray < 0 { return -1 }
	mut binary := gray
	mut remaining := gray >> 1
	for remaining != 0 {
		binary ^= remaining
		remaining >>= 1
	}
	return binary
}
