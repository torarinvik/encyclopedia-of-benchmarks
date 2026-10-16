package determinant

import "core:c"

Max_Dimension :: 6
Max_Input_Length :: 1 + Max_Dimension * Max_Dimension
Invalid_Result :: i64(-9223372036854775807 - 1)

determinant_recursive :: proc(matrix: [^]i64, dimension: int) -> i64 {
	if dimension == 1 do return matrix[0]
	var result: i64 = 0
	var minor: [25]i64
	for column := 0; column < dimension; column += 1 {
		minor_index := 0
		for row := 1; row < dimension; row += 1 {
			for source_column := 0; source_column < dimension; source_column += 1 {
				if source_column != column {
					minor[minor_index] = matrix[row * dimension + source_column]
					minor_index += 1
				}
			}
		}
		term := matrix[column] * determinant_recursive(&minor[0], dimension - 1)
		if column % 2 == 0 do result += term
		else do result -= term
	}
	return result
}

@(export)
determinant :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > Max_Input_Length do return Invalid_Result
	dimension_value := input[0]
	if dimension_value < 1 || dimension_value > Max_Dimension do return Invalid_Result
	dimension := int(dimension_value)
	if length != c.size_t(1 + dimension * dimension) do return Invalid_Result
	for index := 0; index < dimension * dimension; index += 1 {
		if input[1 + index] < -9 || input[1 + index] > 9 do return Invalid_Result
	}
	return determinant_recursive(&input[1], dimension)
}
