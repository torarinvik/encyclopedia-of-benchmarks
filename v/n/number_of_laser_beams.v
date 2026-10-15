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

	mut previous_devices := i64(0)
	mut beams := i64(0)
	for row in 0 .. rows {
		mut devices := i64(0)
		for column in 0 .. columns {
			cell := unsafe { input[2 + row * columns + column] }
			if cell != 48 && cell != 49 { return -1 }
			if cell == 49 { devices++ }
		}
		if devices != 0 {
			beams += devices * previous_devices
			previous_devices = devices
		}
	}
	return beams
}
