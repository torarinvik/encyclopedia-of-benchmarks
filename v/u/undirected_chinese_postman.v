const max_n = 8
const max_m = 12
const inf = i64(1_000_000_000)

@[export: 'undirected_chinese_postman']
pub fn undirected_chinese_postman(input &i64, length usize) i64 {
	if length < 2 || length > 38 { return -1 }
	unsafe {
		if input == nil || input[0] < 1 || input[0] > max_n || input[1] < 0 || input[1] > max_m { return -1 }
		n := int(input[0])
		m := int(input[1])
		if length != usize(2 + 3 * m) { return -1 }
		if n == 1 { return if m == 0 { 0 } else { -1 } }
		if m < n - 1 { return -1 }
		mut distance := [max_n * max_n]i64{}
		mut seen := [max_n * max_n]bool{}
		mut degree := [max_n]int{}
		for u in 0 .. n {
			for v in 0 .. n { distance[u * max_n + v] = if u == v { 0 } else { inf } }
		}
		mut total_weight := i64(0)
		for edge in 0 .. m {
			u_value := input[2 + 3 * edge]
			v_value := input[3 + 3 * edge]
			weight := input[4 + 3 * edge]
		if u_value < 0 || u_value >= i64(n) || v_value < 0 || v_value >= i64(n) || u_value == v_value || weight < 1 || weight > 1000 { return -1 }
			u := int(u_value)
			v := int(v_value)
			if seen[u * max_n + v] { return -1 }
			seen[u * max_n + v] = true
			seen[v * max_n + u] = true
			distance[u * max_n + v] = weight
			distance[v * max_n + u] = weight
			degree[u]++
			degree[v]++
			total_weight += weight
		}
		for middle in 0 .. n {
			for source in 0 .. n {
				for target in 0 .. n {
					candidate := distance[source * max_n + middle] + distance[middle * max_n + target]
					if candidate < distance[source * max_n + target] { distance[source * max_n + target] = candidate }
				}
			}
		}
		for vertex in 0 .. n { if distance[vertex] >= inf { return -1 } }
		mut odd := [max_n]int{}
		mut odd_count := 0
		for vertex in 0 .. n {
			if degree[vertex] & 1 != 0 { odd[odd_count] = vertex; odd_count++ }
		}
		state_count := 1 << odd_count
		mut pairing := [1 << max_n]i64{}
		for mask in 0 .. state_count { pairing[mask] = inf }
		pairing[0] = 0
		for mask in 1 .. state_count {
			mut first := 0
			for mask & (1 << first) == 0 { first++ }
			first_bit := 1 << first
			for partner in first + 1 .. odd_count {
				partner_bit := 1 << partner
				if mask & partner_bit == 0 { continue }
				remaining := mask ^ first_bit ^ partner_bit
				candidate := distance[odd[first] * max_n + odd[partner]] + pairing[remaining]
				if candidate < pairing[mask] { pairing[mask] = candidate }
			}
		}
		return total_weight + pairing[state_count - 1]
	}
}
