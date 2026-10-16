package problem81

import "core:c"

const MAX_DIMENSION = 80
const MAX_CELL_VALUE: i64 = 9999

@(export)
problem81 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	dimension_value := input[0]
	if dimension_value < 1 || dimension_value > i64(MAX_DIMENSION) do return -1
	dimension := int(dimension_value)
	if length != c.size_t(1 + dimension * dimension) do return -1
	for index := 1; index < int(length); index += 1 {
		if input[index] < 0 || input[index] > MAX_CELL_VALUE do return -1
	}

	costs: [MAX_DIMENSION]i64
	costs[0] = input[1]
	for column := 1; column < dimension; column += 1 {
		costs[column] = costs[column - 1] + input[1 + column]
	}
	for row := 1; row < dimension; row += 1 {
		row_offset := 1 + row * dimension
		costs[0] += input[row_offset]
		for column := 1; column < dimension; column += 1 {
			above := costs[column]
			left := costs[column - 1]
			costs[column] = (if above < left then above else left) + input[row_offset + column]
		}
	}
	return costs[dimension - 1]
}
