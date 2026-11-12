module tree_decomposition_width_2

const max_n = 32
const max_m = 64
const max_input = 131
const max_output = 1592

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'tree_decomposition_width_2']
pub fn tree_decomposition_width_2(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		if input[0] < 1 || input[0] > max_n || input[1] < 0 || input[1] > max_m { return -1 }
		n, m := int(input[0]), int(input[1])
		if m > n * (n - 1) / 2 || length != usize(2 + 2 * m) { return -1 }

		mut adjacent := [max_n][max_n]bool{}
		for edge in 0 .. m {
			left64, right64 := input[2 + 2 * edge], input[3 + 2 * edge]
			if left64 < 0 || left64 >= right64 || right64 >= i64(n) { return -1 }
			left, right := int(left64), int(right64)
			if adjacent[left][right] { return -1 }
			adjacent[left][right], adjacent[right][left] = true, true
		}

		mut active := [max_n]bool{}
		for vertex in 0 .. n { active[vertex] = true }
		mut order := [max_n]int{}
		mut bags := [max_n * 3]i64{}
		mut bag_sizes := [max_n]int{}
		mut later := [max_n * 2]int{}
		mut later_counts := [max_n]int{}
		mut position := [max_n]int{}
		for step in 0 .. n {
			mut chosen := -1
			mut neighbors := [2]int{}
			mut count := 0
			for vertex in 0 .. n {
				if !active[vertex] { continue }
				mut degree := 0
				for other in 0 .. n {
					if active[other] && adjacent[vertex][other] { degree++ }
				}
				if degree <= 2 {
					chosen = vertex
					for other in 0 .. n {
						if active[other] && adjacent[vertex][other] {
							neighbors[count] = other
							count++
						}
					}
					break
				}
			}
			if chosen < 0 { return -1 }
			order[step] = chosen
			later_counts[step] = count
			bag_sizes[step] = count + 1
			bags[step * 3] = i64(chosen)
			for index in 0 .. count {
				later[step * 2 + index] = neighbors[index]
				bags[step * 3 + index + 1] = i64(neighbors[index])
			}
			for i in 0 .. count + 1 {
				for j in i + 1 .. count + 1 {
					if bags[step * 3 + j] < bags[step * 3 + i] {
						bags[step * 3 + i], bags[step * 3 + j] = bags[step * 3 + j], bags[step * 3 + i]
					}
				}
			}
			if count == 2 {
				adjacent[neighbors[0]][neighbors[1]] = true
				adjacent[neighbors[1]][neighbors[0]] = true
			}
			active[chosen] = false
		}

		for step in 0 .. n { position[order[step]] = step }
		mut parents := [max_n]int{}
		for step in 0 .. n {
			parents[step] = n
			if later_counts[step] > 0 {
				mut selected := later[step * 2]
				if later_counts[step] == 2 && position[later[step * 2 + 1]] < position[selected] {
					selected = later[step * 2 + 1]
				}
				parents[step] = position[selected]
			}
		}

		bytes := 8 * (6 * n + 7)
		if output == nil || capacity < usize(bytes) || bytes > max_output { return -2 }
		mut staged := [max_output]u8{}
		put_i64(mut &staged[0], 0, i64(n + 1))
		put_i64(mut &staged[0], 8, 2)
		put_i64(mut &staged[0], 16, i64(n))
		mut cursor := 24
		for bag in 0 .. n + 1 {
			mut count := bag_sizes[bag]
			if bag == n { count = 0 }
			put_i64(mut &staged[0], cursor, i64(count))
			cursor += 8
			for slot in 0 .. 3 {
				mut value := i64(-1)
				if slot < count { value = bags[bag * 3 + slot] }
				put_i64(mut &staged[0], cursor, value)
				cursor += 8
			}
		}
		for child in 0 .. n {
			put_i64(mut &staged[0], cursor, i64(child))
			put_i64(mut &staged[0], cursor + 8, i64(parents[child]))
			cursor += 16
		}
		for byte in 0 .. bytes { output[byte] = staged[byte] }
		return i64(bytes)
	}
}
