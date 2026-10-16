module problem81

const max_dimension = 80
const max_cell_value = i64(9999)

@[export: 'problem81']
pub fn problem81(input &i64, length usize) i64 {
	if length < 1 { return -1 }
	dimension_value := unsafe { input[0] }
	if dimension_value < 1 || dimension_value > i64(max_dimension) { return -1 }
	dimension := int(dimension_value)
	if length != usize(1 + dimension * dimension) { return -1 }
	for index in 1 .. int(length) {
		value := unsafe { input[index] }
		if value < 0 || value > max_cell_value { return -1 }
	}

	mut costs := []i64{len: max_dimension}
	costs[0] = unsafe { input[1] }
	for column in 1 .. dimension {
		costs[column] = costs[column - 1] + unsafe { input[1 + column] }
	}
	for row in 1 .. dimension {
		row_offset := 1 + row * dimension
		costs[0] += unsafe { input[row_offset] }
		for column in 1 .. dimension {
			above := costs[column]
			left := costs[column - 1]
			costs[column] = (if above < left { above } else { left }) + unsafe { input[row_offset + column] }
		}
	}
	return costs[dimension - 1]
}
