module counting_c4

@[export: 'counting_c4']
pub fn counting_c4(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if input == nil || length < 2 || length > 26 { return -1 }
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	if n_value < 2 || n_value > 8 || m_value < 1 || m_value > 12 { return -1 }
	n := int(n_value)
	edge_count := int(m_value)
	if length != usize(2 + 2*edge_count) { return -1 }

	mut multiplicity := [8][8]i64{}
	for edge in 0 .. edge_count {
		u_value := unsafe { input[2+2*edge] }
		v_value := unsafe { input[3+2*edge] }
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value { return -1 }
		u := int(u_value)
		v := int(v_value)
		multiplicity[u][v]++
		multiplicity[v][u]++
	}

	mut answers := [12]u64{}
	for edge in 0 .. edge_count {
		u := int(unsafe { input[2+2*edge] })
		v := int(unsafe { input[3+2*edge] })
		for a in 0 .. n {
			if a == u || a == v { continue }
			for b in 0 .. n {
				if b == u || b == v || b == a { continue }
				answers[edge] += u64(multiplicity[u][a] * multiplicity[a][b] * multiplicity[b][v])
			}
		}
	}

	bytes := 8 * edge_count
	if output == nil || output_capacity < bytes { return -2 }
	mut staged := [96]u8{}
	for edge in 0 .. edge_count {
		for byte in 0 .. 8 { staged[8*edge+byte] = u8((answers[edge] >> (8*byte)) & 0xff) }
	}
	unsafe { for byte in 0 .. bytes { output[byte] = staged[byte] } }
	return i64(bytes)
}
