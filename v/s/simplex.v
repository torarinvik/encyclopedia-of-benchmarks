module simplex

const invalid_result = f64(-1.0e300)
const max_finite = f64(1.7976931348623157e308)

fn finite_value(value f64) bool {
	return value == value && value < max_finite && value > -max_finite
}

@[export: 'simplex']
pub fn simplex(input &i64, length usize) f64 {
	if unsafe { input == nil } || length < 4 || length > 132 { return invalid_result }
	n_vars_value := unsafe { input[0] }
	n_artificial_value := unsafe { input[1] }
	n_rows_value := unsafe { input[2] }
	n_cols_value := unsafe { input[3] }
	if n_vars_value < 2 || n_vars_value > 4 || n_artificial_value < 0 || n_artificial_value > 2 ||
		n_rows_value < 3 || n_rows_value > 8 || n_cols_value < n_vars_value + n_artificial_value + 1 ||
		n_cols_value > 16 { return invalid_result }
	rows := int(n_rows_value)
	cols := int(n_cols_value)
	mut artificial := int(n_artificial_value)
	if int(length) != 4 + rows * cols { return invalid_result }
	mut tableau := [8][16]f64{}
	for row in 0 .. rows {
		for col in 0 .. cols {
			tableau[row][col] = f64(unsafe { input[4 + row * cols + col] }) / 1_000_000.0
		}
		if tableau[row][cols - 1] < 0.0 { return invalid_result }
	}

	mut phase_one := artificial != 0
	mut finished := false
	mut active_rows := rows
	mut active_cols := cols
	for _ in 0 .. 100 {
		if finished {
			mut result := tableau[0][active_cols - 1]
			if result < 0.0 { result = -result }
			return if finite_value(result) { result } else { invalid_result }
		}
		stages := if phase_one { 2 } else { 1 }
		sign := if phase_one { 1.0 } else { -1.0 }
		mut pivot_col := 0
		mut best := sign * tableau[0][0]
		for col in 1 .. active_cols - 1 {
			score := sign * tableau[0][col]
			if score > best { best = score; pivot_col = col }
		}
		if best <= 0.0 {
			if phase_one {
				mut compacted := [8][16]f64{}
				first_artificial := active_cols - artificial - 1
				for row in 1 .. active_rows {
					mut new_col := 0
					for col in 0 .. active_cols {
						if col >= first_artificial && col < active_cols - 1 { continue }
						compacted[row - 1][new_col] = tableau[row][col]
						new_col++
					}
				}
				active_rows--
				active_cols -= artificial
				artificial = 0
				tableau = compacted
				phase_one = false
			} else {
				finished = true
			}
			continue
		}

		mut found := false
		mut pivot_row := 0
		mut best_ratio := 0.0
		for row in stages .. active_rows {
			divisor := tableau[row][pivot_col]
			if divisor > 0.0 {
				ratio := tableau[row][active_cols - 1] / divisor
				if !finite_value(ratio) { return invalid_result }
				if !found || ratio < best_ratio {
					found = true
					best_ratio = ratio
					pivot_row = row
				}
			}
		}
		if !found { return invalid_result }

		pivot := tableau[pivot_row][pivot_col]
		mut normalized := [16]f64{}
		for col in 0 .. active_cols { normalized[col] = tableau[pivot_row][col] / pivot }
		mut column_values := [8]f64{}
		for row in 0 .. active_rows { column_values[row] = tableau[row][pivot_col] }
		for row in 0 .. active_rows {
			coefficient := column_values[row]
			for col in 0 .. active_cols { tableau[row][col] += -coefficient * normalized[col] }
		}
		for col in 0 .. active_cols { tableau[pivot_row][col] = normalized[col] }
		for row in 0 .. active_rows {
			for col in 0 .. active_cols {
				if !finite_value(tableau[row][col]) { return invalid_result }
			}
		}
	}
	return invalid_result
}
