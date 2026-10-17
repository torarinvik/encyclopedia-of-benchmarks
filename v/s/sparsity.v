const max_dimension = usize(63)
const max_input_values = usize(3971)
const max_abs_cell = i64(1_000_000)
const invalid_result = -1.0e300

@[export: 'sparsity']
pub fn sparsity(input &i64, length usize) f64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values { return invalid_result }
	unsafe {
		rows_value := input[0]
		columns_value := input[1]
		if rows_value < 1 || rows_value > i64(max_dimension) || columns_value < 1 || columns_value > i64(max_dimension) { return invalid_result }
		rows := int(rows_value)
		columns := int(columns_value)
		total := rows * columns
		if length != usize(2 + total) { return invalid_result }

		mut zero_count := 0
		for index in 0 .. total {
			value := input[2 + index]
			if value < -max_abs_cell || value > max_abs_cell { return invalid_result }
			if value == 0 { zero_count++ }
		}
		return f64(zero_count) / f64(total)
	}
}
