package shootout_matrix

import "core:c"

MATRIX_SIZE :: 10
CELL_COUNT :: MATRIX_SIZE * MATRIX_SIZE
MAX_ITERATIONS :: 4096
MAX_OUTPUT_BYTES :: 23

append_integer :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int, value: int) {
	reversed: [10]u8
	count := 0
	remaining := value
	for {
		reversed[count] = u8(48 + remaining % 10)
		count += 1
		remaining /= 10
		if remaining == 0 do break
	}
	for count > 0 {
		count -= 1
		buffer^[used^] = reversed[count]
		used^ += 1
	}
}

@(export, link_name="shootout_matrix")
shootout_matrix :: proc "c" (iteration_count: i64, output: [^]u8,
	output_capacity: c.size_t) -> i64 {
	if iteration_count < 0 || iteration_count > MAX_ITERATIONS do return -1

	left: [CELL_COUNT]int
	right: [CELL_COUNT]int
	product: [CELL_COUNT]int
	for index := 0; index < CELL_COUNT; index += 1 {
		left[index] = index + 1
		right[index] = index + 1
		product[index] = index + 1
	}

	for iteration := i64(0); iteration < iteration_count; iteration += 1 {
		for row := 0; row < MATRIX_SIZE; row += 1 {
			for column := 0; column < MATRIX_SIZE; column += 1 {
				value := 0
				for inner := 0; inner < MATRIX_SIZE; inner += 1 {
					value += left[row * MATRIX_SIZE + inner] * right[inner * MATRIX_SIZE + column]
				}
				product[row * MATRIX_SIZE + column] = value
			}
		}
	}

	staged: [MAX_OUTPUT_BYTES]u8
	used := 0
	append_integer(&staged, &used, product[0])
	staged[used] = u8(' ')
	used += 1
	append_integer(&staged, &used, product[23])
	staged[used] = u8(' ')
	used += 1
	append_integer(&staged, &used, product[32])
	staged[used] = u8(' ')
	used += 1
	append_integer(&staged, &used, product[44])
	staged[used] = 10
	used += 1

	if output == nil || output_capacity < c.size_t(used) do return -2
	for index := 0; index < used; index += 1 do output[index] = staged[index]
	return i64(used)
}
