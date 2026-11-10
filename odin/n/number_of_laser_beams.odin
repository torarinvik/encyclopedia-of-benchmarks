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

	invalid_bits, previous_devices, beams: u64
	for row_start := 2; row_start < int(length); row_start += columns {
		devices := u64(0)
		for column := 0; column < columns; column += 1 {
			cell := u64(input[row_start + column])
			invalid_bits |= cell ~ 48
			devices += cell & 1
		}
		beams += devices * previous_devices
		if devices != 0 do previous_devices = devices
	}
	if invalid_bits > 1 do return -1
	return i64(beams)
}
