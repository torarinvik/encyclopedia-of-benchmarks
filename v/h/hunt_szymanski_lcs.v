module hunt_szymanski_lcs

// Return the LCS length from matching positions and an LIS tails array.
@[export: 'hunt_szymanski_lcs']
pub fn hunt_szymanski_lcs(input &i64, length usize) i64 {
	if length < 2 || length > 131 { return -1 }
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	if n_value < 0 || n_value > 64 || m_value < 0 || m_value > 64 { return -1 }
	if length != usize(2 + n_value + m_value) { return -1 }
	n := int(n_value)
	m := int(m_value)
	for i in 0 .. n + m {
		value := unsafe { input[2 + i] }
		if value < 0 || value > 127 { return -1 }
	}

	mut right_positions := [8192]i32{init: 0}
	mut position_count := [128]i32{init: 0}
	mut tails := [64]i32{init: 0}
	for j in 0 .. m {
		symbol := int(unsafe { input[2 + n + j] })
		count := int(position_count[symbol])
		right_positions[symbol * 64 + count] = i32(j)
		position_count[symbol] = i32(count + 1)
	}

	mut tail_count := 0
	for i in 0 .. n {
		symbol := int(unsafe { input[2 + i] })
		mut count := int(position_count[symbol])
		for count > 0 {
			count -= 1
			position := right_positions[symbol * 64 + count]
			mut low := 0
			mut high := tail_count
			for low < high {
				middle := low + (high - low) / 2
				if tails[middle] >= position { high = middle }
				else { low = middle + 1 }
			}
			if low == tail_count {
				tails[tail_count] = position
				tail_count++
			} else {
				tails[low] = position
			}
		}
	}
	return i64(tail_count)
}
