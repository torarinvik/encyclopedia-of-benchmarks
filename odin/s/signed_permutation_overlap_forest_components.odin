package signed_permutation_overlap_forest_components

import "core:c"

MAX_N :: 8
MAX_VERTICES :: 2*MAX_N+2
MAX_CYCLES :: MAX_N+1
MAX_INPUT :: MAX_N+2
MAX_OUTPUT_WORDS :: 1+3*MAX_CYCLES
MAX_OUTPUT :: 8*MAX_OUTPUT_WORDS

store_word :: proc(bytes: [^]u8, word: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		bytes[word*8+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
signed_permutation_overlap_forest_components :: proc "c" (input: [^]i64,
	length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n_value := input[0]
	if n_value < 1 || n_value > MAX_N || length != c.size_t(n_value+1) do return -1
	n, vertex_count := int(n_value), int(2*n_value+2)
	pi: [MAX_VERTICES]int
	pi[vertex_count-1] = vertex_count-1
	seen: u16 = 0
	for position := 0; position < n; position += 1 {
		gene := input[position+1]
		if gene == 0 || gene < -n_value || gene > n_value do return -1
		absolute := int(gene)
		if absolute < 0 { absolute = -absolute }
		bit := u16(1 << (absolute-1))
		if (seen & bit) != 0 do return -1
		seen |= bit
		left, right := 2*absolute-1, 2*absolute
		if gene < 0 { left, right = right, left }
		pi[2*position+1], pi[2*position+2] = left, right
	}
	gray: [MAX_VERTICES]int
	for pair := 0; pair <= n; pair += 1 {
		left, right := pi[2*pair], pi[2*pair+1]
		gray[left], gray[right] = right, left
	}
	cycle_of: [MAX_VERTICES]int
	for vertex := 0; vertex < MAX_VERTICES; vertex += 1 { cycle_of[vertex] = -1 }
	begin, end: [MAX_CYCLES]int
	cycle_count := 0
	for seed := 0; seed < vertex_count; seed += 1 {
		if cycle_of[seed] >= 0 { continue }
		cid := cycle_count
		cycle_count += 1
		vertex, low, high := seed, seed, seed
		for cycle_of[vertex] < 0 {
			cycle_of[vertex] = cid
			if vertex < low { low = vertex }
			if vertex > high { high = vertex }
			vertex = gray[vertex^1]
		}
		begin[cid], end[cid] = low, high
	}
	parent: [MAX_CYCLES]int
	for cid := 0; cid < cycle_count; cid += 1 { parent[cid] = cid }
	stack_id, stack_begin, stack_end: [MAX_CYCLES]int
	top := 0
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		cid := cycle_of[vertex]
		low, high := begin[cid], end[cid]
		if vertex == low {
			stack_id[top], stack_begin[top], stack_end[top] = cid, low, high
			top += 1
		}
		extent_begin, extent_end := low, high
		for top > 0 && stack_begin[top-1] > low {
			top -= 1
			popped := stack_id[top]
			if stack_begin[top] < extent_begin { extent_begin = stack_begin[top] }
			if stack_end[top] > extent_end { extent_end = stack_end[top] }
			parent[popped] = cid
		}
		if top == 0 do return -1
		if extent_begin < stack_begin[top-1] { stack_begin[top-1] = extent_begin }
		if extent_end > stack_end[top-1] { stack_end[top-1] = extent_end }
		if vertex == stack_end[top-1] { top -= 1 }
	}
	component: [MAX_CYCLES]int
	for cid := 0; cid < cycle_count; cid += 1 {
		if parent[cid] == cid { component[cid] = begin[cid] }
		else { component[cid] = component[parent[cid]] }
	}
	words: [MAX_OUTPUT_WORDS]i64
	words[0] = i64(cycle_count)
	for cid := 0; cid < cycle_count; cid += 1 {
		words[1+3*cid], words[2+3*cid], words[3+3*cid] =
			i64(begin[cid]), i64(end[cid]), i64(component[cid])
	}
	output_bytes := c.size_t((1+3*cycle_count)*8)
	if output == nil || capacity < output_bytes do return -2
	staged: [MAX_OUTPUT]u8
	for word := 0; word < 1+3*cycle_count; word += 1 { store_word(&staged[0], word, words[word]) }
	for byte := 0; byte < int(output_bytes); byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
