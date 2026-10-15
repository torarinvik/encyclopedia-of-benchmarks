module shortest_common_supersequence_length

// Return the shortest common supersequence length of two packed ASCII sequences.
@[export: 'shortest_common_supersequence_length']
pub fn shortest_common_supersequence_length(packed &i64, length usize) i64 {
	if length < 2 || length > 512 { return -1 }
	left_length := unsafe { packed[0] }
	right_length := unsafe { packed[1] }
	if left_length < 0 || left_length > 255 || right_length < 0 || right_length > 255 { return -1 }
	if length != usize(2 + left_length + right_length) { return -1 }
	for index in 0 .. usize(left_length + right_length) {
		value := unsafe { packed[2 + index] }
		if value < 0 || value > 127 { return -1 }
	}

	rows := int(left_length + 1)
	columns := int(right_length + 1)
	mut table := [65536]i64{init: 0}
	for i in 1 .. rows {
		for j in 1 .. columns {
			cell := i * columns + j
			if unsafe { packed[1 + usize(i)] } == unsafe { packed[1 + usize(left_length) + usize(j)] } {
				table[cell] = table[(i - 1) * columns + j - 1] + 1
			} else {
				above := table[(i - 1) * columns + j]
				left := table[i * columns + j - 1]
				table[cell] = if above > left { above } else { left }
			}
		}
	}
	return left_length + right_length - table[(rows - 1) * columns + columns - 1]
}
