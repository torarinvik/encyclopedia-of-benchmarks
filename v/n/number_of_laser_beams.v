module number_of_laser_beams

const max_dimension = 64
const max_cells = max_dimension * max_dimension

// Count adjacent nonempty-row device pairs in a fixed-width binary bank.
@[export: 'number_of_laser_beams']
pub fn number_of_laser_beams(input &i64, length usize) i64 {
	if length < 2 || length > max_cells + 2 { return -1 }
	rows_value := unsafe { input[0] }
	columns_value := unsafe { input[1] }
	if rows_value < 1 || rows_value > max_dimension || columns_value < 1 || columns_value > max_dimension { return -1 }
	rows := usize(rows_value)
	columns := usize(columns_value)
	if length != rows * columns + 2 { return -1 }

	mut invalid_bits := u64(0)
	mut previous_devices := u64(0)
	mut beams := u64(0)
	mut row_start := usize(2)
	for row_start < length {
		mut devices := u64(0)
		for column in 0 .. columns {
			cell := u64(unsafe { input[row_start + column] })
			invalid_bits |= cell ^ 48
			devices += cell & 1
		}
		beams += devices * previous_devices
		if devices != 0 { previous_devices = devices }
		row_start += columns
	}
	if invalid_bits > 1 { return -1 }
	return i64(beams)
}
