package connectivity_aware_plug_dp_binary_grid_colorings

import "core:c"

Max_States :: 78732
Code_States :: 6561

cell_color :: proc(code: int) -> int {
	if code == 0 do return -1
	return 0 if code <= 4 else 1
}

advance_frontier :: proc(input_codes: [^]int, closed, diagonal, color, row, column: int,
		output_codes: [^]int, output_closed: ^int, output_diagonal: ^int) -> bool {
	if (closed & (1 << color)) != 0 do return false
	above := input_codes[column]
	left := 0 if column == 0 else input_codes[column - 1]
	if row != 0 && column != 0 && cell_color(above) == color &&
		cell_color(left) == color && diagonal == color + 1 do return false

	for slot := 0; slot < 4; slot += 1 { output_codes[slot] = input_codes[slot] }
	output_codes[column] = 0
	above_color := cell_color(above)
	above_label := 0
	if above_color == color { above_label = above; if color == 1 { above_label = above - 4 } }
	left_color := cell_color(left)
	left_label := 0
	if left_color == color { left_label = left; if color == 1 { left_label = left - 4 } }
	chosen_label := above_label if above_label != 0 else left_label
	if above_label != 0 && left_label != 0 && above_label != left_label {
		for slot := 0; slot < 4; slot += 1 {
			if color == 0 && output_codes[slot] == left_label do output_codes[slot] = above_label
			if color == 1 && output_codes[slot] == 4 + left_label do output_codes[slot] = 4 + above_label
		}
		chosen_label = above_label
	}
	if chosen_label == 0 {
		maximum := 0
		for slot := 0; slot < 4; slot += 1 {
			code := output_codes[slot]
			if cell_color(code) == color {
				label := code if color == 0 else code - 4
				if label > maximum do maximum = label
			}
		}
		chosen_label = maximum + 1
	}
	output_codes[column] = chosen_label if color == 0 else 4 + chosen_label

	output_closed^ = closed
	if above != 0 && above_color != color {
		old_still_present := false
		other_same_color := false
		for slot := 0; slot < 4; slot += 1 {
			code := output_codes[slot]
			if code == above do old_still_present = true
			if cell_color(code) == above_color && code != above do other_same_color = true
		}
		if !old_still_present {
			if other_same_color do return false
			output_closed^ = closed | (1 << above_color)
		}
	}

	mapping: [9]int = {}
	next_black, next_white := 0, 0
	for slot := 0; slot < 4; slot += 1 {
		code := output_codes[slot]
		if code == 0 do continue
		if code <= 4 {
			if mapping[code] == 0 { next_black += 1; mapping[code] = next_black }
			output_codes[slot] = mapping[code]
		} else {
			key := code
			if mapping[key] == 0 { next_white += 1; mapping[key] = 4 + next_white }
			output_codes[slot] = mapping[key]
		}
	}
	output_diagonal^ = 0 if above_color < 0 else above_color + 1
	return true
}

encode_state :: proc(codes: [^]int, closed, diagonal: int) -> int {
	powers := [4]int{1, 9, 81, 729}
	code_key := 0
	for slot := 0; slot < 4; slot += 1 { code_key += codes[slot] * powers[slot] }
	return (closed * 3 + diagonal) * Code_States + code_key
}

@(export)
connectivity_aware_plug_dp_binary_grid_colorings :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	rows_value, columns_value := input[0], input[1]
	if rows_value < 2 || rows_value > 4 || columns_value < 2 || columns_value > 4 do return -1
	rows, columns := int(rows_value), int(columns_value)
	dp, next: [Max_States]i64 = {}, {}
	dp[0] = 1
	for cell := 0; cell < rows * columns; cell += 1 {
		row, column := cell / columns, cell % columns
		for state := 0; state < Max_States; state += 1 { next[state] = 0 }
		for state := 0; state < Max_States; state += 1 {
			if dp[state] == 0 do continue
			code_key := state % Code_States
		flags := state / Code_States
		diagonal, closed := flags % 3, flags / 3
		codes: [4]int = {}
		for slot := 0; slot < 4; slot += 1 { codes[slot] = code_key % 9; code_key /= 9 }
		for color := 0; color < 2; color += 1 {
			output_codes: [4]int = {}
			output_closed, output_diagonal := 0, 0
			if advance_frontier(&codes[0], closed, diagonal, color, row, column,
					&output_codes[0], &output_closed, &output_diagonal) {
				destination := encode_state(&output_codes[0], output_closed, output_diagonal)
				next[destination] += dp[state]
			}
		}
		}
		for state := 0; state < Max_States; state += 1 { dp[state] = next[state] }
	}

	total: i64 = 0
	for state := 0; state < Max_States; state += 1 {
		if dp[state] == 0 do continue
		code_key := state % Code_States
		closed := (state / Code_States) / 3
		seen_black: [5]bool = {}
		seen_white: [5]bool = {}
		black_components, white_components := 0, 0
		for slot := 0; slot < 4; slot += 1 {
			code := code_key % 9; code_key /= 9
			if code >= 1 && code <= 4 && !seen_black[code] { seen_black[code] = true; black_components += 1
			} else if code >= 5 && code <= 8 && !seen_white[code - 4] { seen_white[code - 4] = true; white_components += 1 }
		}
		if ((closed & 1) != 0 && black_components == 0 || (closed & 1) == 0 && black_components == 1) &&
			((closed & 2) != 0 && white_components == 0 || (closed & 2) == 0 && white_components == 1) {
			total += dp[state]
		}
	}
	return total
}
