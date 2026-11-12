module bishop_placements_count

fn bpc_diagonal_size(index int) int {
	return if index % 2 == 1 { (index / 4) * 2 + 1 } else { ((index - 1) / 4) * 2 + 2 }
}

fn bpc_color_counts(k int, last_diagonal int) [17]i64 {
	mut dp := [16 * 17]i64{}
	dp[0] = 1
	dp[17] = 1
	if k >= 1 { dp[18] = 1 }
	for diagonal in 2 .. last_diagonal + 1 {
		dp[diagonal * 17] = 1
		squares := bpc_diagonal_size(diagonal)
		for placed in 1 .. k + 1 {
			offset := diagonal * 17 + placed
			previous := (diagonal - 2) * 17
			dp[offset] = dp[previous + placed] + dp[previous + placed - 1] * i64(squares - placed + 1)
		}
	}
	mut counts := [17]i64{}
	for placed in 0 .. k + 1 {
		counts[placed] = dp[last_diagonal * 17 + placed]
	}
	return counts
}

@[export: 'bishop_placements_count']
pub fn bishop_placements_count(input &i64, length usize) i64 {
	if length != 2 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 8 || input[1] < 0 || input[1] > 16 { return -1 }
		n := int(input[0])
		k := int(input[1])
		maximum := if n == 1 { 1 } else { 2 * n - 2 }
		if k > maximum { return 0 }
		black := bpc_color_counts(k, 2 * n - 1)
		white := bpc_color_counts(k, 2 * n - 2)
		mut result := i64(0)
		for left in 0 .. k + 1 { result += black[left] * white[k - left] }
		return result
	}
}
