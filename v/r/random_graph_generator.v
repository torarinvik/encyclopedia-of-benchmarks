@[export: 'random_graph_generator']
pub fn random_graph_generator(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > 2020 { return -1 }
		vertex_count_raw, directed, probability_units := input[0], input[1], input[2]
		if vertex_count_raw < 0 || vertex_count_raw > 64 || (directed != 0 && directed != 1) { return -1 }
		if probability_units < -9007199254740992 || probability_units > 18014398509481984 { return -1 }
		vertex_count := int(vertex_count_raw)
		pair_count := if vertex_count < 2 { 0 } else { vertex_count * (vertex_count - 1) / 2 }
		draw_count := if probability_units > 0 && probability_units < 9007199254740992 { pair_count } else { 0 }
		if input_length != usize(3 + draw_count) { return -1 }
		for index in 0 .. draw_count {
			draw := input[3 + index]
			if draw < 0 || draw >= 9007199254740992 { return -1 }
		}

		mut staged := [4096]u8{}
		if probability_units >= 9007199254740992 {
			for source in 0 .. vertex_count {
				for target in 0 .. vertex_count {
					if source != target { staged[source * vertex_count + target] = 1 }
				}
			}
		} else if probability_units > 0 {
			mut draw_index := 0
			for source in 0 .. vertex_count {
				for target in source + 1 .. vertex_count {
					if input[3 + draw_index] < probability_units {
						staged[source * vertex_count + target] = 1
						if directed == 0 { staged[target * vertex_count + source] = 1 }
					}
					draw_index++
				}
			}
		}

		output_bytes := vertex_count * vertex_count
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. output_bytes { output[index] = staged[index] }
		return i64(output_bytes)
	}
}
