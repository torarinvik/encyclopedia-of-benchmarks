package ryser_permanent

import "core:c"

MAX_DIMENSION :: 8
MAX_INPUT_LENGTH :: 65
INVALID_RESULT :: i64 = -9223372036854775807 - 1

bit_count :: proc(value: int) -> int {
	remaining := value
	count := 0
	for remaining != 0 {
		count += remaining & 1
		remaining >>= 1
	}
	return count
}

@(export)
ryser_permanent :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
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

	var row_sums: [MAX_DIMENSION]i64
	var total: i64 = 0
	previous_gray := 0
	subset_count := 1 << n
	for ordinal := 0; ordinal < subset_count; ordinal += 1 {
		gray := ordinal ^ (ordinal >> 1)
		if ordinal != 0 {
			changed := gray ^ previous_gray
			column := 0
			for ((changed >> column) & 1) == 0 { column += 1 }
			direction: i64 = 1
			if (gray & changed) == 0 { direction = -1 }
			for row := 0; row < n; row += 1 {
				row_sums[row] += direction * matrix[row*n+column]
			}
		}

		product: i64 = 1
		for row := 0; row < n; row += 1 { product *= row_sums[row] }
		if ((n+bit_count(gray)) & 1) != 0 { product = -product }
		total += product
		previous_gray = gray
	}
	return total
}
