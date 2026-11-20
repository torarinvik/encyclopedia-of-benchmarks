module hits_fixed_point

const max_n = 16
const max_m = 64
const max_input = 131
const max_parseable = 132
const scale = i64(1000000)

@[export: 'hits_fixed_point']
pub fn hits_fixed_point(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > usize(max_parseable) { return -1 }
		n_value, m_value, k_value := input[0], input[1], input[2]
		if n_value < 1 || n_value > max_n || m_value < 0 || m_value > max_m || k_value < 0 || k_value > 32 {
			return -1
		}
		n, m, k := int(n_value), int(m_value), int(k_value)
		if int(length) != 3 + 2 * m || length > usize(max_input) { return -1 }

		mut arc_from := [64]int{}
		mut arc_to := [64]int{}
		for arc in 0 .. m {
			u_value, v_value := input[3 + 2 * arc], input[4 + 2 * arc]
			if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value {
				return -1
			}
			arc_from[arc], arc_to[arc] = int(u_value), int(v_value)
			for previous in 0 .. arc {
				if arc_from[previous] == arc_from[arc] && arc_to[previous] == arc_to[arc] { return -1 }
			}
		}

		mut authority := [16]i64{}
		mut hub := [16]i64{}
		for vertex in 0 .. n { hub[vertex] = scale }
		for _ in 0 .. k {
			mut raw := [16]i64{}
			for arc in 0 .. m { raw[arc_to[arc]] += hub[arc_from[arc]] }
			mut authority_total := i64(0)
			for vertex in 0 .. n { authority_total += raw[vertex] }
			for vertex in 0 .. n {
				if authority_total == 0 { authority[vertex] = 0 }
				else { authority[vertex] = raw[vertex] * scale / authority_total }
			}

			for vertex in 0 .. n { raw[vertex] = 0 }
			for arc in 0 .. m { raw[arc_from[arc]] += authority[arc_to[arc]] }
			mut hub_total := i64(0)
			for vertex in 0 .. n { hub_total += raw[vertex] }
			for vertex in 0 .. n {
				if hub_total == 0 { hub[vertex] = 0 }
				else { hub[vertex] = raw[vertex] * scale / hub_total }
			}
		}

		mut checksum := i64(0)
		for vertex in 0 .. n {
			checksum += i64(vertex + 1) * (authority[vertex] + 65537 * hub[vertex])
		}
		return checksum
	}
}
