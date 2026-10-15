module count_segments

const max_length = 4096

// Count transitions from ASCII space to a non-space byte.
@[export: 'count_segments']
pub fn count_segments(input &i64, length usize) i64 {
	if length > max_length { return -1 }
	mut count := i64(0)
	mut previous_was_space := true
	for index in 0 .. length {
		value := unsafe { input[index] }
		if value < 1 || value > 127 { return -1 }
		if value != 32 && previous_was_space { count++ }
		previous_was_space = value == 32
	}
	return count
}
