module olden_em3d

const max_nodes = 8
const max_degree = 4

@[export: 'olden_em3d']
pub fn olden_em3d(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if isnil(input) || input_length < 2 { return -1 }
		rn, rd := input[0], input[1]
		if rn != rn || rd != rd || rn < 1.0 || rn > f64(max_nodes) || f64(int(rn)) != rn || rd < 1.0 || rd > f64(max_degree) || f64(int(rd)) != rd { return -1 }
		n, degree := int(rn), int(rd)
		edges := n * degree
		if input_length != usize(2 + 2*n + 4*edges) { return -1 }
		mut electric := [max_nodes]f64{}
		mut magnetic := [max_nodes]f64{}
		mut offset := 2
		for i in 0 .. n { if input[offset+i] != input[offset+i] || input[offset+i] < 0.0 || input[offset+i] > 1.0 { return -1 }; electric[i] = input[offset+i] }
		offset += n
		for i in 0 .. n { if input[offset+i] != input[offset+i] || input[offset+i] < 0.0 || input[offset+i] > 1.0 { return -1 }; magnetic[i] = input[offset+i] }
		offset += n
		e_neighbors := offset; offset += edges
		e_coefficients := offset; offset += edges
		h_neighbors := offset; offset += edges
		h_coefficients := offset
		for i in 0 .. edges {
			en, hn := input[e_neighbors+i], input[h_neighbors+i]
			if en != en || en < 0.0 || en >= f64(n) || f64(int(en)) != en || hn != hn || hn < 0.0 || hn >= f64(n) || f64(int(hn)) != hn { return -1 }
			if input[e_coefficients+i] != input[e_coefficients+i] || input[e_coefficients+i] < 0.0 || input[e_coefficients+i] > 1.0 || input[h_coefficients+i] != input[h_coefficients+i] || input[h_coefficients+i] < 0.0 || input[h_coefficients+i] > 1.0 { return -1 }
			start := (i / degree) * degree
			for j in start .. i { if input[e_neighbors+j] == en || input[h_neighbors+j] == hn { return -1 } }
		}
		if isnil(output) || output_capacity < usize(2*n) { return -2 }
		for node in 0 .. n {
			mut current := electric[node]
			base := node * degree
			for edge in 0 .. degree { coefficient := base + (edge & ~1); current -= input[e_coefficients+coefficient] * magnetic[int(input[e_neighbors+base+edge])] }
			electric[node] = current
		}
		for node in 0 .. n {
			mut current := magnetic[node]
			base := node * degree
			for edge in 0 .. degree { coefficient := base + (edge & ~1); current -= input[h_coefficients+coefficient] * electric[int(input[h_neighbors+base+edge])] }
			magnetic[node] = current
		}
		for i in 0 .. n { output[i] = electric[i]; output[n+i] = magnetic[i] }
		return i64(2*n)
	}
}
