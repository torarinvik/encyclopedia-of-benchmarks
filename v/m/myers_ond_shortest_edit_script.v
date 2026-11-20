// Myers furthest-reaching edit-graph search for a bounded byte script.
module myers_ond_shortest_edit_script

const max_sequence = 16
const max_distance = 32
const max_output = 48
const offset = 33
const diagonals = 67

fn build_script(input &i64) ([max_output]u8, int) {
	unsafe {
		n := int(input[0])
		m := int(input[1])
		mut frontier := [diagonals]int{init: -1}
		mut trace := [max_distance + 1][diagonals]int{}
		for d in 0 .. max_distance + 1 {
			for i in 0 .. diagonals { trace[d][i] = -1 }
		}
		frontier[offset + 1] = 0

		mut found_distance := -1
		mut found_diagonal := 0
		for distance := 0; distance <= n + m && found_distance < 0; distance++ {
			for diagonal := -distance; diagonal <= distance; diagonal += 2 {
				slot := offset + diagonal
				mut x := 0
				if diagonal == -distance || (diagonal != distance && frontier[slot - 1] < frontier[slot + 1]) {
					x = frontier[slot + 1]
				} else {
					x = frontier[slot - 1] + 1
				}
				mut y := x - diagonal
				for x < n && y < m && input[2 + x] == input[2 + n + y] {
					x++
					y++
				}
				frontier[slot] = x
				trace[distance][slot] = x
				if x >= n && y >= m {
					found_distance = distance
					found_diagonal = diagonal
					break
				}
			}
		}

		mut reverse_ops := [max_distance]u8{}
		mut reverse_symbols := [max_distance]u8{}
		mut path_length := 0
		mut x := n
		mut y := m
		mut diagonal := found_diagonal
		for distance := found_distance; distance > 0; distance-- {
			slot := offset + diagonal
			mut previous_diagonal := 0
			mut previous_x := 0
			mut previous_y := 0
			mut snake_x := 0
			mut snake_y := 0
			if diagonal == -distance || (diagonal != distance && trace[distance - 1][slot - 1] < trace[distance - 1][slot + 1]) {
				previous_diagonal = diagonal + 1
				previous_x = trace[distance - 1][offset + previous_diagonal]
				previous_y = previous_x - previous_diagonal
				snake_x = previous_x
				snake_y = previous_y + 1
				for x > snake_x && y > snake_y {
					reverse_ops[path_length] = 0
					reverse_symbols[path_length] = 0
					path_length++
					x--
					y--
				}
				reverse_ops[path_length] = 2
				reverse_symbols[path_length] = u8(input[2 + n + previous_y])
				path_length++
			} else {
				previous_diagonal = diagonal - 1
				previous_x = trace[distance - 1][offset + previous_diagonal]
				previous_y = previous_x - previous_diagonal
				snake_x = previous_x + 1
				snake_y = previous_y
				for x > snake_x && y > snake_y {
					reverse_ops[path_length] = 0
					reverse_symbols[path_length] = 0
					path_length++
					x--
					y--
				}
				reverse_ops[path_length] = 1
				reverse_symbols[path_length] = 0
				path_length++
			}
			x = previous_x
			y = previous_y
			diagonal = previous_diagonal
		}

		for i in 0 .. trace[0][offset] {
			reverse_ops[path_length] = 0
			reverse_symbols[path_length] = 0
			path_length++
		}
		mut result := [max_output]u8{}
		mut written := 0
		for step_index := 0; step_index < path_length; step_index++ {
			step := path_length - step_index - 1
			operation := reverse_ops[step]
			result[written] = operation
			written++
			if operation == 2 {
				result[written] = reverse_symbols[step]
				written++
			}
		}
		return result, written
	}
}

@[export: 'myers_ond_shortest_edit_script']
pub fn myers_ond_shortest_edit_script(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 2 + 2 * max_sequence { return -1 }
		n_value := input[0]
		m_value := input[1]
		if n_value < 0 || n_value > max_sequence || m_value < 0 || m_value > max_sequence { return -1 }
		n := int(n_value)
		m := int(m_value)
		if int(length) != 2 + n + m { return -1 }
		for i in 0 .. n + m {
			if input[2 + i] < 0 || input[2 + i] > 255 { return -1 }
		}
		result, needed := build_script(input)
		if output == nil || output_capacity < usize(needed) { return -2 }
		for i in 0 .. needed { output[i] = result[i] }
		return i64(needed)
	}
}
