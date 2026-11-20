module minimum_weight_cycle_floyd

const max_n = 9
const max_cells = 81
const max_input_length = 111
const inf = i64(1152921504606846976)

fn minimum_weight_cycle_floyd_store(mut output &u8, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'minimum_weight_cycle_floyd']
pub fn minimum_weight_cycle_floyd(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		n_value, m_value := input[0], input[1]
		if n_value < 3 || n_value > max_n || m_value < 0
			|| m_value > n_value * (n_value - 1) / 2 { return -1 }
		n, m := int(n_value), int(m_value)
		if length != usize(2 + 3*m) { return -1 }

		mut edge := [max_cells]i64{}
		mut dist := [max_cells]i64{}
		for i in 0 .. n {
			for j in 0 .. n {
				edge[i*max_n+j] = inf
				if i == j { edge[i*max_n+j] = 0 }
			}
		}
		for e in 0 .. m {
			offset := 2 + 3*e
			u_value, v_value, weight := input[offset], input[offset+1], input[offset+2]
			if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
				|| u_value == v_value || weight < 1 || weight > 1000 { return -1 }
			u, v := int(u_value), int(v_value)
			if edge[u*max_n+v] != inf { return -1 }
			edge[u*max_n+v], edge[v*max_n+u] = weight, weight
		}
		if output == nil || capacity < 8 { return -2 }
		for i in 0 .. n {
			for j in 0 .. n { dist[i*max_n+j] = edge[i*max_n+j] }
		}

		mut best := inf
		for k in 0 .. n {
			for i in 0 .. k {
				if edge[i*max_n+k] == inf { continue }
				for j in (i+1) .. k {
					if edge[k*max_n+j] == inf || dist[i*max_n+j] == inf { continue }
					candidate := edge[i*max_n+k] + edge[k*max_n+j] + dist[i*max_n+j]
					if candidate < best { best = candidate }
				}
			}
			for i in 0 .. n {
				if dist[i*max_n+k] == inf { continue }
				for j in 0 .. n {
					if dist[k*max_n+j] == inf { continue }
					candidate := dist[i*max_n+k] + dist[k*max_n+j]
					if candidate < dist[i*max_n+j] { dist[i*max_n+j] = candidate }
				}
			}
		}
		minimum_weight_cycle_floyd_store(mut output, if best == inf { -1 } else { best })
		return 8
	}
}
