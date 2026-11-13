package bareiss_determinant

import "core:c"

MAX_DIMENSION :: 8
MAX_INPUT_LENGTH :: 65
INVALID_RESULT :: i64 = -9223372036854775807 - 1

@(export)
bareiss_determinant :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	if input[0] < 1 || input[0] > MAX_DIMENSION do return INVALID_RESULT
	n := int(input[0])
	if int(length) != 1+n*n do return INVALID_RESULT

	var matrix: [MAX_DIMENSION*MAX_DIMENSION]i64
	for index := 0; index < n*n; index += 1 {
		value := input[1+index]
		if value < -4 || value > 4 do return INVALID_RESULT
		matrix[index] = value
	}

	sign: i64 = 1
	previous_pivot: i64 = 1
	for k := 0; k+1 < n; k += 1 {
		if matrix[k*n+k] == 0 {
			replacement := k+1
			for replacement < n && matrix[replacement*n+k] == 0 {
				replacement += 1
			}
			if replacement == n do return 0
			for column := 0; column < n; column += 1 {
				temporary := matrix[k*n+column]
				matrix[k*n+column] = matrix[replacement*n+column]
				matrix[replacement*n+column] = temporary
			}
			sign = -sign
		}

		pivot := matrix[k*n+k]
		for row := k+1; row < n; row += 1 {
			for column := k+1; column < n; column += 1 {
				numerator := matrix[row*n+column]*pivot - matrix[row*n+k]*matrix[k*n+column]
				matrix[row*n+column] = numerator / previous_pivot
			}
			matrix[row*n+k] = 0
		}
		previous_pivot = pivot
	}
	return sign * matrix[(n-1)*n+n-1]
}
