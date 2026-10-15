package number_of_laser_beams

import "core:c"

MAX_DIMENSION :: 64
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION

// Count adjacent nonempty-row device pairs in a fixed-width binary bank.
@(export)
number_of_laser_beams :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_CELLS + 2 do return -1
	if input[0] < 1 || input[0] > MAX_DIMENSION || input[1] < 1 || input[1] > MAX_DIMENSION do return -1
	rows := int(input[0])
	columns := int(input[1])
	if length != c.size_t(rows * columns + 2) do return -1

	previous_devices := i64(0)
	beams := i64(0)
	for row := 0; row < rows; row += 1 {
		devices := i64(0)
		for column := 0; column < columns; column += 1 {
			cell := input[2 + row * columns + column]
			if cell != 48 && cell != 49 do return -1
			if cell == 49 do devices += 1
		}
		if devices != 0 {
			beams += devices * previous_devices
			previous_devices = devices
		}
	}
	return beams
}
