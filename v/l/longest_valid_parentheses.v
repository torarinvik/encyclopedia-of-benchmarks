module longest_valid_parentheses

const max_length = 4096

// Memoized endpoint recurrence, evaluated bottom-up from right to left.
@[export: 'longest_valid_parentheses']
pub fn longest_valid_parentheses(input &i64, length usize) i64 {
	if length > max_length { return -1 }
	for index in 0 .. length {
		value := unsafe { input[index] }
		if value != 40 && value != 41 { return -1 }
	}
	mut end_exclusive := [max_length]usize{init: 0}
	mut best := usize(0)
	mut remaining := length
	for remaining > 0 {
		remaining--
		index := remaining
		if unsafe { input[index] } == 40 {
			if index + 1 < length && unsafe { input[index + 1] } == 41 {
				end_exclusive[index] = index + 2
				if index + 2 < length && end_exclusive[index + 2] > end_exclusive[index] {
					end_exclusive[index] = end_exclusive[index + 2]
				}
			} else if index + 1 < length {
				nested_end := end_exclusive[index + 1]
				if nested_end > 0 && nested_end < length && unsafe { input[nested_end] } == 41 {
					end_exclusive[index] = nested_end + 1
					if nested_end + 1 < length && end_exclusive[nested_end + 1] > end_exclusive[index] {
						end_exclusive[index] = end_exclusive[nested_end + 1]
					}
				}
			}
		}
		if end_exclusive[index] > index && end_exclusive[index] - index > best {
			best = end_exclusive[index] - index
		}
	}
	return i64(best)
}
