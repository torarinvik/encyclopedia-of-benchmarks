package hypercube_edge_monotonicity_tester

import "core:c"

store_i64_le :: proc(output: [^]u8, offset: c.size_t, value: i64) {
	bits := transmute(u64)value
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> (byte * 8))
	}
}

@(export)
hypercube_edge_monotonicity_tester :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 130 do return -1
	n_value, q_value := input[0], input[1]
	if n_value < 1 || n_value > 6 || q_value < 1 || q_value > 32 do return -1
	n, q := c.size_t(n_value), c.size_t(q_value)
	domain := c.size_t(1) << n
	if length != 2 + domain + 2 * q do return -1
	for vertex := c.size_t(0); vertex < domain; vertex += 1 {
		if input[2 + vertex] != 0 && input[2 + vertex] != 1 do return -1
	}
	tape := 2 + domain
	for round := c.size_t(0); round < q; round += 1 {
		vertex, coordinate := input[tape + 2 * round], input[tape + 2 * round + 1]
		if vertex < 0 || u64(vertex) >= u64(domain) || coordinate < 0 || u64(coordinate) >= u64(n) do return -1
	}
	accepted, rounds := i64(1), i64(0)
	for round := c.size_t(0); round < q; round += 1 {
		vertex := c.size_t(input[tape + 2 * round])
		bit := c.size_t(1) << c.size_t(input[tape + 2 * round + 1])
		lower := vertex & ~bit
		rounds += 1
		if input[2 + lower] > input[2 + (lower | bit)] { accepted = 0; break }
	}
	if output == nil || capacity < 24 do return -2
	store_i64_le(output, 0, accepted)
	store_i64_le(output, 8, rounds)
	store_i64_le(output, 16, 2 * rounds)
	return 24
}
