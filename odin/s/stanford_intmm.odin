package stanford_intmm

import "core:c"

ROWSIZE :: 40
CELL_COUNT :: ROWSIZE * ROWSIZE
MAX_PASSES :: 10

decimal_width :: proc(value: i32) -> int {
	magnitude := i64(value)
	if magnitude < 0 do magnitude = -magnitude
	width := 0
	if value < 0 do width = 1
	for {
		width += 1
		magnitude /= 10
		if magnitude == 0 do break
	}
	return width
}

write_decimal :: proc(value: i32, output: [^]u8, position: int) -> int {
	magnitude := i64(value)
	mut cursor := position
	if magnitude < 0 {
		output[cursor] = u8('-')
		cursor += 1
		magnitude = -magnitude
	}
	reversed: [10]u8
	count := 0
	for {
		reversed[count] = u8(48 + magnitude % 10)
		count += 1
		magnitude /= 10
		if magnitude == 0 do break
	}
	for count > 0 {
		count -= 1
		output[cursor] = reversed[count]
		cursor += 1
	}
	return cursor
}

@(export, link_name="stanford_intmm")
stanford_intmm :: proc "c" (pass_count: i64, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if pass_count < 1 || pass_count > MAX_PASSES do return -1

	mut a: [CELL_COUNT]i32
	mut b: [CELL_COUNT]i32
	mut product: [CELL_COUNT]i32
	mut diagonal: [MAX_PASSES]i32
	for pass := 0; pass < int(pass_count); pass += 1 {
		mut seed := i64(74755)
		for index := 0; index < CELL_COUNT; index += 1 {
			seed = (seed * 1309 + 13849) & 65535
			a[index] = i32(seed % 120 - 60)
		}
		for index := 0; index < CELL_COUNT; index += 1 {
			seed = (seed * 1309 + 13849) & 65535
			b[index] = i32(seed % 120 - 60)
		}

		for row := 0; row < ROWSIZE; row += 1 {
			for column := 0; column < ROWSIZE; column += 1 {
				sum := i32(0)
				for inner := 0; inner < ROWSIZE; inner += 1 {
					sum += a[row * ROWSIZE + inner] * b[inner * ROWSIZE + column]
				}
				product[row * ROWSIZE + column] = sum
			}
		}
		diagonal[pass] = product[pass * ROWSIZE + pass]
	}

	mut required := 0
	for pass := 0; pass < int(pass_count); pass += 1 {
		required += decimal_width(diagonal[pass]) + 1
	}
	if output == nil || output_capacity < c.size_t(required) do return -2

	mut position := 0
	for pass := 0; pass < int(pass_count); pass += 1 {
		position = write_decimal(diagonal[pass], output, position)
		output[position] = 10
		position += 1
	}
	return i64(position)
}
