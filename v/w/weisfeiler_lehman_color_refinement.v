const max_vertices = 8
const max_input_length = 9
const invalid_result = i64(-1)
const degree_color_place = i64(43046721)

fn bit_count(value_input i64) int {
	mut value := value_input
	mut count := 0
	for value != 0 {
		count += int(value & 1)
		value >>= 1
	}
	return count
}

@[export: 'weisfeiler_lehman_color_refinement']
pub fn weisfeiler_lehman_color_refinement(input &i64, length usize) i64 {
	if length < 1 || length > max_input_length+1 { return invalid_result }
	unsafe {
		if input == nil || input[0] < 0 || input[0] > max_vertices { return invalid_result }
		n := int(input[0])
		if length != usize(1+n) { return invalid_result }
		allowed := (i64(1) << n)-1
		mut adjacency := [max_vertices]i64{}
		mut colors := [max_vertices]i64{}
		mut next_colors := [max_vertices]i64{}
		mut class_count := 0
		for vertex in 0 .. n {
			mask := input[1+vertex]
			if mask < 0 || (mask & ~allowed) != 0 || (mask & (i64(1) << vertex)) != 0 { return invalid_result }
			adjacency[vertex] = mask
			colors[vertex] = i64(bit_count(mask))
			mut first_degree := true
			for prior in 0 .. vertex {
				if colors[prior] == colors[vertex] { first_degree = false }
				if ((adjacency[vertex] >> prior) & 1) != ((adjacency[prior] >> vertex) & 1) { return invalid_result }
			}
			if first_degree { class_count++ }
		}
		if n == 0 { return 0 }

		for {
			mut keys := [max_vertices]i64{}
			mut unique_keys := [max_vertices]i64{}
			mut unique_count := 0
			for vertex in 0 .. n {
				mut neighbor_colors := [max_vertices]i64{}
				mut neighbor_count := 0
				for neighbor in 0 .. n {
					if (adjacency[vertex] & (i64(1) << neighbor)) == 0 { continue }
					value := colors[neighbor]
					mut position := neighbor_count
					for position > 0 && neighbor_colors[position-1] > value {
						neighbor_colors[position] = neighbor_colors[position-1]
						position--
					}
					neighbor_colors[position] = value
					neighbor_count++
				}
				mut suffix := i64(0)
				for slot in 0 .. max_vertices {
					suffix = suffix*9
					if slot < neighbor_count { suffix += neighbor_colors[slot]+1 }
				}
				keys[vertex] = colors[vertex]*degree_color_place+suffix
				mut seen := false
				for prior in 0 .. vertex { if keys[prior] == keys[vertex] { seen = true } }
				if !seen { unique_keys[unique_count] = keys[vertex]; unique_count++ }
			}
			for index in 1 .. unique_count {
				value := unique_keys[index]
				mut position := index
				for position > 0 && unique_keys[position-1] > value {
					unique_keys[position] = unique_keys[position-1]
					position--
				}
				unique_keys[position] = value
			}
			for vertex in 0 .. n {
				mut rank := 0
				for unique_keys[rank] != keys[vertex] { rank++ }
				next_colors[vertex] = i64(rank)
			}
			for vertex in 0 .. n { colors[vertex] = next_colors[vertex] }
			if unique_count == class_count { break }
			class_count = unique_count
		}

		mut packed := i64(0)
		mut place := i64(1)
		for vertex in 0 .. n {
			packed += colors[vertex]*place
			place *= 9
		}
		return packed
	}
}
