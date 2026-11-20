module hypercube_edge_monotonicity_tester

fn hem_store_i64(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'hypercube_edge_monotonicity_tester']
pub fn hypercube_edge_monotonicity_tester(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 130 { return -1 }
	unsafe {
		n_value := input[0]
		q_value := input[1]
		if n_value < 1 || n_value > 6 || q_value < 1 || q_value > 32 { return -1 }
		n := int(n_value)
		q := int(q_value)
		domain := 1 << n
		if int(length) != 2 + domain + 2 * q { return -1 }
		for vertex in 0 .. domain {
			if input[2 + vertex] != 0 && input[2 + vertex] != 1 { return -1 }
		}
		tape := 2 + domain
		for round in 0 .. q {
			vertex := input[tape + 2 * round]
			coordinate := input[tape + 2 * round + 1]
			if vertex < 0 || vertex >= i64(domain) || coordinate < 0 || coordinate >= n_value { return -1 }
		}
		mut accepted := i64(1)
		mut rounds := i64(0)
		for round in 0 .. q {
			vertex := int(input[tape + 2 * round])
			bit := 1 << int(input[tape + 2 * round + 1])
			lower := vertex & ~bit
			rounds++
			if input[2 + lower] > input[2 + (lower | bit)] {
				accepted = 0
				break
			}
		}
		if output == nil || capacity < 24 { return -2 }
		hem_store_i64(mut output, 0, accepted)
		hem_store_i64(mut output, 8, rounds)
		hem_store_i64(mut output, 16, 2 * rounds)
		return 24
	}
}
