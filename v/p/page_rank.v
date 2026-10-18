import math

const max_nodes = 4

@[export: 'page_rank']
pub fn page_rank(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 6 || input_length > 18 { return -1 }
		for i in 0 .. 2 {
			if !input[i].is_finite() || math.floor(input[i]) != input[i] { return -1 }
		}
		if input[0] < 2 || input[0] > 4 || input[1] < 0 || input[1] > 8 { return -1 }
		nodes := int(input[0])
		iterations := int(input[1])
		if input_length != usize(2 + nodes * nodes) { return -1 }
		mut matrix := [16]u8{}
		mut degrees := [max_nodes]int{}
		for row in 0 .. nodes {
			for column in 0 .. nodes {
				value := input[2 + row * nodes + column]
				if !value.is_finite() || (value != 0 && value != 1) || (row == column && value != 0) { return -1 }
				matrix[row * nodes + column] = u8(value)
				degrees[row] += int(matrix[row * nodes + column])
			}
		}
		mut ranks := [max_nodes]f64{}
		for i in 0 .. nodes { ranks[i] = 1.0 / f64(nodes) }
		for _ in 0 .. iterations {
			mut dangling_sum := 0.0
			for source in 0 .. nodes {
				if degrees[source] == 0 { dangling_sum += ranks[source] }
			}
			dangling_share := (dangling_sum * 0.5) / f64(nodes)
			baseline := 0.5 / f64(nodes) + dangling_share
			mut next := [max_nodes]f64{}
			for target in 0 .. nodes {
				mut incoming := 0.0
				for source in 0 .. nodes {
					if matrix[source * nodes + target] == 1 {
						incoming += ranks[source] / f64(degrees[source])
					}
				}
				next[target] = baseline + incoming * 0.5
			}
			ranks = next
		}
		if output == nil || capacity < usize(nodes) { return -2 }
		for i in 0 .. nodes { output[i] = ranks[i] }
		return i64(nodes)
	}
}
