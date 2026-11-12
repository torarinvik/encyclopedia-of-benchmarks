const max_n = 512
const modulus = i64(998244353)

fn mod_pow(base_value i64, exponent_value int) i64 {
	mut result := i64(1)
	mut base := base_value
	mut exponent := exponent_value
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

fn solve(n int) i64 {
	mut factorial := [max_n + 1]i64{}
	mut inverse_factorial := [max_n + 1]i64{}
	mut all_graphs := [max_n + 1]i64{}
	mut connected := [max_n + 1]i64{}
	factorial[0] = 1
	for i in 1 .. n + 1 { factorial[i] = factorial[i - 1] * i64(i) % modulus }
	inverse_factorial[n] = mod_pow(factorial[n], 998244351)
	for i := n; i > 0; i-- { inverse_factorial[i - 1] = inverse_factorial[i] * i64(i) % modulus }

	all_graphs[0] = 1
	mut edge_choices := i64(1)
	for size in 1 .. n + 1 {
		all_graphs[size] = all_graphs[size - 1] * edge_choices % modulus
		edge_choices = edge_choices * 2 % modulus
	}
	connected[1] = 1
	for size in 2 .. n + 1 {
		mut disconnected := i64(0)
		for component_size in 1 .. size {
			mut choose := factorial[size - 1] * inverse_factorial[component_size - 1] % modulus
			choose = choose * inverse_factorial[size - component_size] % modulus
			mut term := choose * connected[component_size] % modulus
			term = term * all_graphs[size - component_size] % modulus
			disconnected = (disconnected + term) % modulus
		}
		connected[size] = (all_graphs[size] - disconnected + modulus) % modulus
	}
	return connected[n]
}

@[export: 'connected_labeled_graph_count']
pub fn connected_labeled_graph_count(input &i64, length usize) i64 {
	if length != 1 { return -1 }
	unsafe {
		if input == nil || input[0] < 1 || input[0] > max_n { return -1 }
		return solve(int(input[0]))
	}
}
