package problem76

Max_Total :: 200
Max_Parts :: 200
Memo_Size :: (Max_Total + 1) * Max_Parts

@(export)
problem76 :: proc "c" (total: i64) -> i64 {
	if total < 1 || total > Max_Total do return -1
	bound := int(total)
	memo: [Memo_Size]i64
	for n := 0; n <= bound; n += 1 { memo[n * Max_Parts] = 1 }
	for n := 0; n <= bound; n += 1 {
		for k := 1; k < bound; k += 1 {
			index := n * Max_Parts + k
			memo[index] += memo[index - 1]
			if n > k do memo[index] += memo[(n - k - 1) * Max_Parts + k]
		}
	}
	return memo[bound * Max_Parts + bound - 1] - 1
}
