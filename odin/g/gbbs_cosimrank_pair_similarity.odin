// Clean-room exact dyadic CoSimRank profile; see package LICENSE.txt.
package gbbs_cosimrank_pair_similarity
import "core:c"

MAX_N :: 8
MAX_M :: 24
MAX_INPUT :: 53

store_scaled_binary64 :: proc "contextless" (output: [^]u8, numerator: u32) {
	bits: u64 = 0
	if numerator != 0 {
		high := 0
		probe := numerator
		for probe > 1 { probe >>= 1; high += 1 }
		exponent := u64(1003 + high)
		significand := u64(numerator) << u64(52 - high)
		bits = (exponent << 52) | (significand & ((u64(1) << 52) - 1))
	}
	for byte := 0; byte < 8; byte += 1 { output[byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
gbbs_cosimrank_pair_similarity :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_INPUT do return -1
	n64, m64, source_u64, source_v64, iterations64 := input[0], input[1], input[2], input[3], input[4]
	if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || source_u64 < 0 || source_u64 >= n64 ||
		source_v64 < 0 || source_v64 >= n64 || iterations64 < 1 || iterations64 > 4 ||
		length != c.size_t(5 + 2*m64) do return -1
	n, m := int(n64), int(m64)
	from: [MAX_M]int
	to: [MAX_M]int
	degree: [MAX_N]int
	seen: [MAX_N*MAX_N]bool
	for edge := 0; edge < m; edge += 1 {
		from64, to64 := input[5+2*edge], input[6+2*edge]
		if from64 < 0 || from64 >= n64 || to64 < 0 || to64 >= n64 || from64 == to64 do return -1
		u, v := int(from64), int(to64)
		if seen[u*MAX_N+v] do return -1
		seen[u*MAX_N+v] = true; from[edge] = u; to[edge] = v; degree[u] += 1
	}
	for vertex := 0; vertex < n; vertex += 1 {
		if degree[vertex] != 0 && degree[vertex] != 1 && degree[vertex] != 2 && degree[vertex] != 4 do return -1
	}
	if output == nil || capacity < 8 do return -2
	current_u: [MAX_N]u32
	current_v: [MAX_N]u32
	next_u: [MAX_N]u32
	next_v: [MAX_N]u32
	current_u[int(source_u64)] = 256; current_v[int(source_v64)] = 256
	numerator: u32 = 0
	if source_u64 == source_v64 do numerator = u32(1) << 20
	for step := 0; step < int(iterations64); step += 1 {
		for edge := 0; edge < m; edge += 1 {
			u, v := from[edge], to[edge]
			next_u[v] += current_u[u] / u32(degree[u])
			next_v[v] += current_v[u] / u32(degree[u])
		}
		dot: u32 = 0
		for vertex := 0; vertex < n; vertex += 1 { dot += next_u[vertex] * next_v[vertex] }
		numerator += dot << u32(3-step)
		for vertex := 0; vertex < n; vertex += 1 {
			current_u[vertex] = next_u[vertex]; current_v[vertex] = next_v[vertex]
			next_u[vertex] = 0; next_v[vertex] = 0
		}
	}
	store_scaled_binary64(output, numerator)
	return 8
}
