package problem345

import "core:c"

MAX_DIMENSION :: 15
MAX_STATES :: 1 << MAX_DIMENSION

bit_count :: proc(value_input: u32) -> i64 {
	value := value_input
	count := i64(0)
	for value != 0 {
		count += i64(value & 1)
		value >>= 1
	}
	return count
}

@(export)
problem345 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_DIMENSION * MAX_DIMENSION + 1 do return -1
	dimension := input[0]
	if dimension < 1 || dimension > MAX_DIMENSION || int(length) != int(dimension * dimension) + 1 do return -1
	for index := 1; index < int(length); index += 1 {
		if input[index] < 0 || input[index] > 1000 do return -1
	}
	best := make([]i64, MAX_STATES)
	defer delete(best)
	for mask := 0; mask < MAX_STATES; mask += 1 { best[mask] = -1 }
	best[0] = 0
	state_count := 1 << int(dimension)
	for mask := 0; mask < state_count; mask += 1 {
		if best[mask] < 0 do continue
		row := int(bit_count(u32(mask)))
		if row >= int(dimension) do continue
		for column := 0; column < int(dimension); column += 1 {
			bit := 1 << column
			if (mask & bit) != 0 do continue
			next := mask | bit
			candidate := best[mask] + input[1 + row * int(dimension) + column]
			if candidate > best[next] { best[next] = candidate }
		}
	}
	return best[state_count - 1]
}
