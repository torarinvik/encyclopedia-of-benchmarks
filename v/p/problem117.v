module problem117

@[export: 'problem117']
pub fn problem117(length i64) i64 {
	if length < 0 || length > 67 { return -1 }
	mut ways := [68]i64{}
	ways[0] = 1
	for row in 1 .. int(length) + 1 {
		ways[row] = ways[row - 1]
		if row >= 2 { ways[row] += ways[row - 2] }
		if row >= 3 { ways[row] += ways[row - 3] }
		if row >= 4 { ways[row] += ways[row - 4] }
	}
	return ways[int(length)]
}
