module contains_duplicate

const max_values = 1024

// Sort a private copy, then scan neighbors for duplicates.
fn sift_down(values &i64, root_start int, length int) {
	mut root := root_start
	for root < length / 2 {
		mut child := root * 2 + 1
		if child + 1 < length && unsafe { values[child] < values[child + 1] } { child++ }
		if unsafe { values[root] >= values[child] } { break }
		temporary := unsafe { values[root] }
		unsafe {
			values[root] = values[child]
			values[child] = temporary
		}
		root = child
	}
}

// Accepts signed 32-bit values; returns 1 if any repeat, 0 otherwise, -1 if invalid.
@[export: 'contains_duplicate']
pub fn contains_duplicate(input &i64, length usize) i64 {
	if length > max_values { return -1 }
	mut values := [max_values]i64{}
	count := int(length)
	for index in 0 .. count {
		value := unsafe { input[index] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[index] = value
	}
	for start := count / 2; start > 0; start-- {
		sift_down(&values[0], start - 1, count)
	}
	for ending := count; ending > 1; ending-- {
		temporary := values[0]
		values[0] = values[ending - 1]
		values[ending - 1] = temporary
		sift_down(&values[0], 0, ending - 1)
	}
	for index in 1 .. count {
		if values[index - 1] == values[index] { return 1 }
	}
	return 0
}
