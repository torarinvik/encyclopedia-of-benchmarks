module connectivity_aware_plug_dp_binary_grid_colorings

const code_states = 6561
const max_states = 78732

fn cell_color(code int) int {
	if code == 0 { return -1 }
	return if code <= 4 { 0 } else { 1 }
}

fn advance_frontier(input_codes [4]int, closed int, diagonal int, color int,
	row int, column int, mut output_codes [4]int, mut output_closed int,
	mut output_diagonal int) bool {
	if (closed & (1 << color)) != 0 { return false }
	above := input_codes[column]
	left := if column == 0 { 0 } else { input_codes[column - 1] }
	if row != 0 && column != 0 && cell_color(above) == color &&
		cell_color(left) == color && diagonal == color + 1 { return false }

	output_codes = input_codes
	output_codes[column] = 0
	above_color := cell_color(above)
	above_label := if above_color == color { if color == 0 { above } else { above - 4 } } else { 0 }
	left_label := if cell_color(left) == color { if color == 0 { left } else { left - 4 } } else { 0 }
	mut chosen_label := if above_label != 0 { above_label } else { left_label }
	if above_label != 0 && left_label != 0 && above_label != left_label {
		for slot in 0 .. 4 {
			if color == 0 && output_codes[slot] == left_label { output_codes[slot] = above_label }
			if color == 1 && output_codes[slot] == 4 + left_label { output_codes[slot] = 4 + above_label }
		}
		chosen_label = above_label
	}
	if chosen_label == 0 {
		mut maximum := 0
		for code in output_codes {
			if cell_color(code) == color {
				label := if color == 0 { code } else { code - 4 }
				if label > maximum { maximum = label }
			}
		}
		chosen_label = maximum + 1
	}
	output_codes[column] = if color == 0 { chosen_label } else { 4 + chosen_label }

	output_closed = closed
	if above != 0 && above_color != color {
		mut old_still_present := false
		mut other_same_color := false
		for code in output_codes {
			if code == above { old_still_present = true }
			if cell_color(code) == above_color && code != above { other_same_color = true }
		}
		if !old_still_present {
			if other_same_color { return false }
			output_closed = closed | (1 << above_color)
		}
	}

	mut mapping := [9]int{}
	mut next_black := 0
	mut next_white := 0
	for slot in 0 .. 4 {
		code := output_codes[slot]
		if code == 0 { continue }
		if code <= 4 {
			if mapping[code] == 0 { next_black++; mapping[code] = next_black }
			output_codes[slot] = mapping[code]
		} else {
			key := code
			if mapping[key] == 0 { next_white++; mapping[key] = 4 + next_white }
			output_codes[slot] = mapping[key]
		}
	}
	output_diagonal = if above_color < 0 { 0 } else { above_color + 1 }
	return true
}

fn encode_state(codes [4]int, closed int, diagonal int) int {
	powers := [4]int{1, 9, 81, 729}
	mut code_key := 0
	for slot in 0 .. 4 { code_key += codes[slot] * powers[slot] }
	return (closed * 3 + diagonal) * code_states + code_key
}

@[export: 'connectivity_aware_plug_dp_binary_grid_colorings']
pub fn connectivity_aware_plug_dp_binary_grid_colorings(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		rows_value := input[0]
		columns_value := input[1]
		if rows_value < 2 || rows_value > 4 || columns_value < 2 || columns_value > 4 { return -1 }
		rows := int(rows_value)
		columns := int(columns_value)
		mut dp := [max_states]i64{}
		mut next := [max_states]i64{}
		dp[0] = 1
		for cell in 0 .. rows * columns {
			row := cell / columns
			column := cell % columns
			for state in 0 .. max_states { next[state] = 0 }
			for state in 0 .. max_states {
				if dp[state] == 0 { continue }
				mut code_key := state % code_states
				flags := state / code_states
				diagonal := flags % 3
				closed := flags / 3
				mut codes := [4]int{}
				for slot in 0 .. 4 { codes[slot] = code_key % 9; code_key /= 9 }
				for color in 0 .. 2 {
					mut output_codes := [4]int{}
					mut output_closed := 0
					mut output_diagonal := 0
					if advance_frontier(codes, closed, diagonal, color, row, column,
						mut output_codes, mut output_closed, mut output_diagonal) {
						destination := encode_state(output_codes, output_closed, output_diagonal)
						next[destination] += dp[state]
					}
				}
			}
			for state in 0 .. max_states { dp[state] = next[state] }
		}

		mut total := i64(0)
		for state in 0 .. max_states {
			if dp[state] == 0 { continue }
			mut code_key := state % code_states
			closed := (state / code_states) / 3
			mut seen_black := [5]bool{}
			mut seen_white := [5]bool{}
			mut black_components := 0
			mut white_components := 0
			for _ in 0 .. 4 {
				code := code_key % 9
				code_key /= 9
				if code >= 1 && code <= 4 && !seen_black[code] {
					seen_black[code] = true
					black_components++
				} else if code >= 5 && code <= 8 && !seen_white[code - 4] {
					seen_white[code - 4] = true
					white_components++
				}
			}
			if ((closed & 1) != 0 && black_components == 0 || (closed & 1) == 0 && black_components == 1) &&
				((closed & 2) != 0 && white_components == 0 || (closed & 2) == 0 && white_components == 1) {
				total += dp[state]
			}
		}
		return total
	}
}
