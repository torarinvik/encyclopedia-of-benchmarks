package counting_c4

import "core:c"

@(export)
counting_c4 :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 26 do return -1
	n_value, m_value := input[0], input[1]
	if n_value < 2 || n_value > 8 || m_value < 1 || m_value > 12 do return -1
	n, edge_count := int(n_value), int(m_value)
	if length != c.size_t(2 + 2*edge_count) do return -1

	multiplicity: [8][8]i64 = 0
	for edge := 0; edge < edge_count; edge += 1 {
		u_value, v_value := input[2+2*edge], input[3+2*edge]
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value do return -1
		u, v := int(u_value), int(v_value)
		multiplicity[u][v] += 1
		multiplicity[v][u] += 1
	}

	answers: [12]u64 = 0
	for edge := 0; edge < edge_count; edge += 1 {
		u, v := int(input[2+2*edge]), int(input[3+2*edge])
		for a := 0; a < n; a += 1 {
			if a == u || a == v do continue
			for b := 0; b < n; b += 1 {
				if b == u || b == v || b == a do continue
				answers[edge] += u64(multiplicity[u][a] * multiplicity[a][b] * multiplicity[b][v])
			}
		}
	}

	bytes := 8 * edge_count
	if output == nil || output_capacity < c.size_t(bytes) do return -2
	staged: [96]u8 = 0
	for edge := 0; edge < edge_count; edge += 1 {
		for byte := 0; byte < 8; byte += 1 { staged[8*edge+byte] = u8((answers[edge] >> (8*byte)) & 0xff) }
	}
	for byte := 0; byte < bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(bytes)
}
