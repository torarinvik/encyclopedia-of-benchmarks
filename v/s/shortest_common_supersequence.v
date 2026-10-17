module shortest_common_supersequence

@[export: 'shortest_common_supersequence']
pub fn shortest_common_supersequence(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > 130 { return -1 }
	m_value := unsafe { input[0] }
	n_value := unsafe { input[1] }
	if m_value < 0 || m_value > 64 || n_value < 0 || n_value > 64 { return -1 }
	m := int(m_value)
	n := int(n_value)
	if length != usize(2 + m + n) { return -1 }
	for index in 0 .. m + n {
		value := unsafe { input[2 + index] }
		if value < 32 || value > 126 { return -1 }
	}

	mut lcs := [4225]i64{init: 0}
	for i in 1 .. m + 1 {
		for j in 1 .. n + 1 {
			cell := i * 65 + j
			if unsafe { input[1 + i] } == unsafe { input[1 + m + j] } {
				lcs[cell] = lcs[(i - 1) * 65 + j - 1] + 1
			} else {
				above := lcs[(i - 1) * 65 + j]
				left := lcs[i * 65 + j - 1]
				lcs[cell] = if above > left { above } else { left }
			}
		}
	}

	mut reversed := [128]u8{}
	mut used := 0
	mut i := m
	mut j := n
	for i > 0 && j > 0 {
		if unsafe { input[1 + i] } == unsafe { input[1 + m + j] } {
			reversed[used] = u8(unsafe { input[1 + i] })
			used++
			i--
			j--
		} else if lcs[(i - 1) * 65 + j] > lcs[i * 65 + j - 1] {
			reversed[used] = u8(unsafe { input[1 + i] })
			used++
			i--
		} else {
			// The pinned implementations choose Y when the LCS values tie.
			reversed[used] = u8(unsafe { input[1 + m + j] })
			used++
			j--
		}
	}
	for i > 0 {
		reversed[used] = u8(unsafe { input[1 + i] })
		used++
		i--
	}
	for j > 0 {
		reversed[used] = u8(unsafe { input[1 + m + j] })
		used++
		j--
	}

	if output == nil || capacity < usize(used) { return -2 }
	for index in 0 .. used {
		unsafe { output[index] = reversed[used - 1 - index] }
	}
	return i64(used)
}
