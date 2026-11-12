package tree_decomposition_width_2

import "core:c"

MAX_N :: 32
MAX_M :: 64
MAX_INPUT :: 131
MAX_OUTPUT :: 1592

put_i64 :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
tree_decomposition_width_2 :: proc "c" (
	input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t,
) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT || input[0] < 1 ||
		input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M {
		return -1
	}
	n, m := int(input[0]), int(input[1])
	if m > n*(n-1)/2 || length != c.size_t(2+2*m) { return -1 }

	adjacent: [MAX_N][MAX_N]bool
	for edge := 0; edge < m; edge += 1 {
		left64, right64 := input[2+2*edge], input[3+2*edge]
		if left64 < 0 || left64 >= right64 || right64 >= i64(n) { return -1 }
		left, right := int(left64), int(right64)
		if adjacent[left][right] { return -1 }
		adjacent[left][right], adjacent[right][left] = true, true
	}

	active: [MAX_N]bool
	order: [MAX_N]int
	bags: [MAX_N*3]i64
	bag_sizes: [MAX_N]int
	later: [MAX_N*2]int
	later_counts: [MAX_N]int
	position: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 { active[vertex] = true }
	for step := 0; step < n; step += 1 {
		chosen := -1
		neighbors: [2]int
		count := 0
		for vertex := 0; vertex < n; vertex += 1 {
			if !active[vertex] { continue }
			degree := 0
			for other := 0; other < n; other += 1 {
				if active[other] && adjacent[vertex][other] { degree += 1 }
			}
			if degree <= 2 {
				chosen = vertex
				for other := 0; other < n; other += 1 {
					if active[other] && adjacent[vertex][other] {
						neighbors[count] = other
						count += 1
					}
				}
				break
			}
		}
		if chosen < 0 { return -1 }
		order[step] = chosen
		later_counts[step] = count
		bag_sizes[step] = count + 1
		bags[step*3] = i64(chosen)
		for index := 0; index < count; index += 1 {
			later[step*2+index] = neighbors[index]
			bags[step*3+index+1] = i64(neighbors[index])
		}
		for i := 0; i < count+1; i += 1 {
			for j := i+1; j < count+1; j += 1 {
				if bags[step*3+j] < bags[step*3+i] {
					bags[step*3+i], bags[step*3+j] = bags[step*3+j], bags[step*3+i]
				}
			}
		}
		if count == 2 {
			adjacent[neighbors[0]][neighbors[1]] = true
			adjacent[neighbors[1]][neighbors[0]] = true
		}
		active[chosen] = false
	}

	for step := 0; step < n; step += 1 { position[order[step]] = step }
	parents: [MAX_N]int
	for step := 0; step < n; step += 1 {
		parents[step] = n
		if later_counts[step] > 0 {
			selected := later[step*2]
			if later_counts[step] == 2 && position[later[step*2+1]] < position[selected] {
				selected = later[step*2+1]
			}
			parents[step] = position[selected]
		}
	}

	bytes := 8 * (6*n + 7)
	if output == nil || capacity < c.size_t(bytes) || bytes > MAX_OUTPUT { return -2 }
	staged: [MAX_OUTPUT]u8
	put_i64(&staged[0], 0, i64(n+1))
	put_i64(&staged[0], 8, 2)
	put_i64(&staged[0], 16, i64(n))
	cursor := 24
	for bag := 0; bag < n+1; bag += 1 {
		count := bag_sizes[bag]
		if bag == n { count = 0 }
		put_i64(&staged[0], cursor, i64(count))
		cursor += 8
		for slot := 0; slot < 3; slot += 1 {
			value := i64(-1)
			if slot < count { value = bags[bag*3+slot] }
			put_i64(&staged[0], cursor, value)
			cursor += 8
		}
	}
	for child := 0; child < n; child += 1 {
		put_i64(&staged[0], cursor, i64(child))
		put_i64(&staged[0], cursor+8, i64(parents[child]))
		cursor += 16
	}
	for byte := 0; byte < bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(bytes)
}
