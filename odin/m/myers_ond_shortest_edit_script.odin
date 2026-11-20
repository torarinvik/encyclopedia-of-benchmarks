// Myers furthest-reaching edit-graph search for a bounded byte script.
package myers_ond_shortest_edit_script

import "core:c"

MAX_SEQUENCE :: 16
MAX_DISTANCE :: 32
MAX_OUTPUT :: 48
OFFSET :: 33
DIAGONALS :: 67

Script :: struct {
	bytes: [MAX_OUTPUT]u8,
	length: int,
}

build_script :: proc(input: [^]i64) -> Script {
	n := int(input[0])
	m := int(input[1])
	frontier: [DIAGONALS]int = {}
	trace: [MAX_DISTANCE + 1][DIAGONALS]int = {}
	for i := 0; i < DIAGONALS; i += 1 {
		frontier[i] = -1
		for d := 0; d <= MAX_DISTANCE; d += 1 {
			trace[d][i] = -1
		}
	}
	frontier[OFFSET + 1] = 0

	found_distance := -1
	found_diagonal := 0
	for distance := 0; distance <= n + m && found_distance < 0; distance += 1 {
		for diagonal := -distance; diagonal <= distance; diagonal += 2 {
			slot := OFFSET + diagonal
			var x: int
			if diagonal == -distance || (diagonal != distance && frontier[slot - 1] < frontier[slot + 1]) {
				x = frontier[slot + 1]
			} else {
				x = frontier[slot - 1] + 1
			}
			y := x - diagonal
			for x < n && y < m && input[2 + x] == input[2 + n + y] {
				x += 1
				y += 1
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

	var reverse_ops: [MAX_DISTANCE]u8 = {}
	var reverse_symbols: [MAX_DISTANCE]u8 = {}
	path_length := 0
	x := n
	y := m
	diagonal := found_diagonal
	for distance := found_distance; distance > 0; distance -= 1 {
		slot := OFFSET + diagonal
		var previous_diagonal, previous_x, previous_y, snake_x, snake_y: int
		if diagonal == -distance || (diagonal != distance && trace[distance - 1][slot - 1] < trace[distance - 1][slot + 1]) {
			previous_diagonal = diagonal + 1
			previous_x = trace[distance - 1][OFFSET + previous_diagonal]
			previous_y = previous_x - previous_diagonal
			snake_x = previous_x
			snake_y = previous_y + 1
			for x > snake_x && y > snake_y {
				reverse_ops[path_length] = 0
				reverse_symbols[path_length] = 0
				path_length += 1
				x -= 1
				y -= 1
			}
			reverse_ops[path_length] = 2
			reverse_symbols[path_length] = u8(input[2 + n + previous_y])
			path_length += 1
		} else {
			previous_diagonal = diagonal - 1
			previous_x = trace[distance - 1][OFFSET + previous_diagonal]
			previous_y = previous_x - previous_diagonal
			snake_x = previous_x + 1
			snake_y = previous_y
			for x > snake_x && y > snake_y {
				reverse_ops[path_length] = 0
				reverse_symbols[path_length] = 0
				path_length += 1
				x -= 1
				y -= 1
			}
			reverse_ops[path_length] = 1
			reverse_symbols[path_length] = 0
			path_length += 1
		}
		x = previous_x
		y = previous_y
		diagonal = previous_diagonal
	}

	for i := 0; i < trace[0][OFFSET]; i += 1 {
		reverse_ops[path_length] = 0
		reverse_symbols[path_length] = 0
		path_length += 1
	}
	result: [MAX_OUTPUT]u8 = {}
	written := 0
	for step_index := 0; step_index < path_length; step_index += 1 {
		step := path_length - step_index - 1
		operation := reverse_ops[step]
		result[written] = operation
		written += 1
		if operation == 2 {
			result[written] = reverse_symbols[step]
			written += 1
		}
	}
	return Script{bytes = result, length = written}
}

@(export)
myers_ond_shortest_edit_script :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 2 + 2 * MAX_SEQUENCE do return -1
	n_value := input[0]
	m_value := input[1]
	if n_value < 0 || n_value > MAX_SEQUENCE || m_value < 0 || m_value > MAX_SEQUENCE do return -1
	n := int(n_value)
	m := int(m_value)
	if int(length) != 2 + n + m do return -1
	for i := 0; i < n + m; i += 1 {
		if input[2 + i] < 0 || input[2 + i] > 255 do return -1
	}

	script := build_script(input)
	if output == nil || output_capacity < c.size_t(script.length) do return -2
	for i := 0; i < script.length; i += 1 do output[i] = script.bytes[i]
	return i64(script.length)
}
