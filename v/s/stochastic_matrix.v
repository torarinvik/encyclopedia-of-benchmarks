const max_dimension = usize(63)
const max_input_values = usize(3972)
const max_abs_cell = i64(1_000_000_000_000)
const cell_scale = 1.0e12
const tolerance = 1.0e-9

@[export: 'stochastic_matrix']
pub fn stochastic_matrix(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_values { return -1 }
	unsafe {
		mode := input[0]
		rows_value := input[1]
		columns_value := input[2]
		if (mode != 0 && mode != 1) || rows_value < 1 || rows_value > i64(max_dimension) ||
			columns_value < 1 || columns_value > i64(max_dimension) { return -1 }

		rows := int(rows_value)
		columns := int(columns_value)
		total := rows * columns
		if length != usize(3 + total) { return -1 }

		for index in 0 .. total {
			units := input[3 + index]
			if units < -max_abs_cell || units > max_abs_cell { return -1 }
		}

		if mode == 0 {
			for row in 0 .. rows {
				mut sum := 0.0
				for column in 0 .. columns {
					value := f64(input[3 + row * columns + column]) / cell_scale
					if value < 0.0 { return 0 }
					sum += value
				}
				difference := sum - 1.0
				if difference > tolerance || difference < -tolerance { return 0 }
			}
		} else {
			for column in 0 .. columns {
				mut sum := 0.0
				for row in 0 .. rows {
					value := f64(input[3 + row * columns + column]) / cell_scale
					if value < 0.0 { return 0 }
					sum += value
				}
				difference := sum - 1.0
				if difference > tolerance || difference < -tolerance { return 0 }
			}
		}
		return 1
	}
}
