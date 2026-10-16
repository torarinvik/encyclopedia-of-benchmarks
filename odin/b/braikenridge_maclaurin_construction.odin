package braikenridge_maclaurin_construction

import "core:c"

determinant :: proc "contextless" (features: [5][6]i64, coefficient: int) -> i64 {
	columns := [30]int{1,2,3,4,5, 0,2,3,4,5, 0,1,3,4,5,
		0,1,2,4,5, 0,1,2,3,5, 0,1,2,3,4}
	paths: [32]i64
	paths[0] = 1
	for row in 0 ..< 5 {
		next: [32]i64
		for mask in 0 ..< 32 {
			selected := 0
			for bit_index in 0 ..< 5 { selected += int((mask >> u32(bit_index)) & 1) }
			if selected != row || paths[mask] == 0 do continue
			for column in 0 ..< 5 {
				bit := 1 << u32(column)
				if mask & bit != 0 do continue
				inversions := 0
				for previous in column + 1 ..< 5 { inversions += int((mask >> u32(previous)) & 1) }
				term := paths[mask] * features[row][columns[coefficient * 5 + column]]
				if inversions & 1 == 0 do next[mask | bit] += term
				else do next[mask | bit] -= term
			}
		}
		paths = next
	}
	return paths[31]
}

@(export)
braikenridge_maclaurin_construction :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 10 do return -2
	features: [5][6]i64
	for point in 0 ..< 5 {
		x := values[2 * point]
		y := values[2 * point + 1]
		if x < -10 || x > 10 || y < -10 || y > 10 do return -2
		features[point] = {x * x, x * y, y * y, x, y, 1}
	}
	coefficients: [6]i64
	for index in 0 ..< 6 {
		value := determinant(features, index)
		coefficients[index] = value
		if index & 1 != 0 do coefficients[index] = -value
	}
	if output == nil || output_capacity < 48 do return -2
	for index in 0 ..< 6 {
		for byte in 0 ..< 8 { output[index * 8 + byte] = u8((coefficients[index] >> u32(8 * byte)) & 0xff) }
	}
	return 6
}
