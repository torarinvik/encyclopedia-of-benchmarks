package connected_labeled_graph_count

import "core:c"

MAX_N :: 512
MODULUS :: i64(998244353)

mod_pow :: proc(base_value: i64, exponent_value: int) -> i64 {
	result := i64(1)
	base := base_value
	exponent := exponent_value
	for exponent > 0 {
		if (exponent & 1) != 0 do result = result * base % MODULUS
		base = base * base % MODULUS
		exponent >>= 1
	}
	return result
}

solve :: proc(n: int) -> i64 {
	factorial, inverse_factorial, all_graphs, connected: [MAX_N + 1]i64
	factorial = {}
	inverse_factorial = {}
	all_graphs = {}
	connected = {}
	factorial[0] = 1
	for i := 1; i <= n; i += 1 {
		factorial[i] = factorial[i - 1] * i64(i) % MODULUS
	}
	inverse_factorial[n] = mod_pow(factorial[n], 998244351)
	for i := n; i > 0; i -= 1 {
		inverse_factorial[i - 1] = inverse_factorial[i] * i64(i) % MODULUS
	}

	all_graphs[0] = 1
	edge_choices := i64(1)
	for size := 1; size <= n; size += 1 {
		all_graphs[size] = all_graphs[size - 1] * edge_choices % MODULUS
		edge_choices = edge_choices * 2 % MODULUS
	}
	connected[1] = 1
	for size := 2; size <= n; size += 1 {
		disconnected := i64(0)
		for component_size := 1; component_size < size; component_size += 1 {
			choose := factorial[size - 1] * inverse_factorial[component_size - 1] % MODULUS
			choose = choose * inverse_factorial[size - component_size] % MODULUS
			term := choose * connected[component_size] % MODULUS
			term = term * all_graphs[size - component_size] % MODULUS
			disconnected = (disconnected + term) % MODULUS
		}
		connected[size] = (all_graphs[size] - disconnected + MODULUS) % MODULUS
	}
	return connected[n]
}

@(export)
connected_labeled_graph_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	return solve(int(input[0]))
}
