package minimum_weight_cycle_floyd

import "core:c"

MAX_N :: 9
MAX_CELLS :: 81
MAX_INPUT_LENGTH :: 111
INF :: i64(1152921504606846976)

store_i64_le :: proc "contextless" (output: [^]u8, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
minimum_weight_cycle_floyd :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) { return -1 }
	n_value, m_value := input[0], input[1]
	if n_value < 3 || n_value > MAX_N || m_value < 0
		|| m_value > n_value*(n_value-1)/2 { return -1 }
	n, m := int(n_value), int(m_value)
	if length != c.size_t(2 + 3*m) { return -1 }

	edge := [MAX_CELLS]i64{}
	dist := [MAX_CELLS]i64{}
	for i := 0; i < n; i += 1 {
		for j := 0; j < n; j += 1 {
			edge[i*MAX_N+j] = INF
			if i == j { edge[i*MAX_N+j] = 0 }
		}
	}
	for e := 0; e < m; e += 1 {
		offset := 2 + 3*e
		u_value, v_value, weight := input[offset], input[offset+1], input[offset+2]
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
			|| u_value == v_value || weight < 1 || weight > 1000 { return -1 }
		u, v := int(u_value), int(v_value)
		if edge[u*MAX_N+v] != INF { return -1 }
		edge[u*MAX_N+v], edge[v*MAX_N+u] = weight, weight
	}
	if output == nil || capacity < 8 { return -2 }
	for i := 0; i < n; i += 1 {
		for j := 0; j < n; j += 1 { dist[i*MAX_N+j] = edge[i*MAX_N+j] }
	}

	best := INF
	for k := 0; k < n; k += 1 {
		for i := 0; i < k; i += 1 {
			if edge[i*MAX_N+k] == INF { continue }
			for j := i+1; j < k; j += 1 {
				if edge[k*MAX_N+j] == INF || dist[i*MAX_N+j] == INF { continue }
				candidate := edge[i*MAX_N+k] + edge[k*MAX_N+j] + dist[i*MAX_N+j]
				if candidate < best { best = candidate }
			}
		}
		for i := 0; i < n; i += 1 {
			if dist[i*MAX_N+k] == INF { continue }
			for j := 0; j < n; j += 1 {
				if dist[k*MAX_N+j] == INF { continue }
				candidate := dist[i*MAX_N+k] + dist[k*MAX_N+j]
				if candidate < dist[i*MAX_N+j] { dist[i*MAX_N+j] = candidate }
			}
		}
	}
	store_i64_le(output, if best == INF { -1 } else { best })
	return 8
}
