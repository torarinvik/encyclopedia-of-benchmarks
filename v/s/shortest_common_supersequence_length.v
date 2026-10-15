module shortest_common_supersequence_length

// Return shortest common supersequence length for two packed ASCII sequences.
@[export: 'shortest_common_supersequence_length']
pub fn shortest_common_supersequence_length(packed &i64, length usize) i64 {
	if length < 2 || length > 512 { return -1 }
	m := unsafe { packed[0] }
	n := unsafe { packed[1] }
	if m < 0 || m > 255 || n < 0 || n > 255 { return -1 }
	if length != usize(2 + m + n) { return -1 }
	for k in 0 .. usize(m + n) {
		value := unsafe { packed[2 + k] }
		if value < 0 || value > 127 { return -1 }
	}

	columns := int(n + 1)
	mut dp := [65536]i64{init: 0}
	for i in 1 .. int(m) + 1 {
		for j in 1 .. int(n) + 1 {
			cell := i * columns + j
			if unsafe { packed[1 + usize(i)] } == unsafe { packed[1 + usize(m) + usize(j)] } {
				dp[cell] = dp[(i - 1) * columns + j - 1] + 1
			} else {
				above := dp[(i - 1) * columns + j]
				left := dp[i * columns + j - 1]
				dp[cell] = if above > left { above } else { left }
			}
		}
	}
	return m + n - dp[int(m) * columns + int(n)]
}
