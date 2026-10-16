module braikenridge_maclaurin_construction

fn feature_column(coefficient int, position int) int {
	if coefficient == 0 { return position + 1 }
	if coefficient == 1 { return if position == 0 { 0 } else { position + 1 } }
	if coefficient == 2 { return if position < 2 { position } else { position + 1 } }
	if coefficient == 3 { return if position < 3 { position } else { position + 1 } }
	if coefficient == 4 { return if position < 4 { position } else { position + 1 } }
	return position
}

fn determinant(features [30]i64, coefficient int) i64 {
	mut paths := [32]i64{}
	paths[0] = 1
	for row in 0 .. 5 {
		mut next := [32]i64{}
		for mask in 0 .. 32 {
			mut selected := 0
			for bit_index in 0 .. 5 { selected += (mask >> bit_index) & 1 }
			if selected != row || paths[mask] == 0 { continue }
			for column in 0 .. 5 {
				bit := 1 << column
				if mask & bit != 0 { continue }
				mut inversions := 0
				for previous in column + 1 .. 5 { inversions += (mask >> previous) & 1 }
				term := paths[mask] * features[row * 6 + feature_column(coefficient, column)]
				if inversions & 1 == 0 { next[mask | bit] += term } else { next[mask | bit] -= term }
			}
		}
		paths = next
	}
	return paths[31]
}

@[export: 'braikenridge_maclaurin_construction']
pub fn braikenridge_maclaurin_construction(values &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if length != 10 { return -2 }
		mut features := [30]i64{}
		for point in 0 .. 5 {
			x := values[2 * point]
			y := values[2 * point + 1]
			if x < -10 || x > 10 || y < -10 || y > 10 { return -2 }
			features[point * 6] = x * x
			features[point * 6 + 1] = x * y
			features[point * 6 + 2] = y * y
			features[point * 6 + 3] = x
			features[point * 6 + 4] = y
			features[point * 6 + 5] = 1
		}
		mut coefficients := [6]i64{}
		for index in 0 .. 6 {
			value := determinant(features, index)
			coefficients[index] = if index % 2 == 0 { value } else { -value }
		}
		if output == nil || output_capacity < 48 { return -2 }
		for index in 0 .. 6 {
			for byte in 0 .. 8 { output[index * 8 + byte] = u8((coefficients[index] >> (8 * byte)) & 0xff) }
		}
		return 6
	}
}
