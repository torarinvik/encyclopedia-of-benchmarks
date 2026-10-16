package problem117

@(export)
problem117 :: proc "c" (length: i64) -> i64 {
	if length < 0 || length > 67 do return -1
	ways: [68]i64 = {}
	ways[0] = 1
	for row := i64(1); row <= length; row += 1 {
		ways[row] = ways[row - 1]
		if row >= 2 do ways[row] += ways[row - 2]
		if row >= 3 do ways[row] += ways[row - 3]
		if row >= 4 do ways[row] += ways[row - 4]
	}
	return ways[length]
}
