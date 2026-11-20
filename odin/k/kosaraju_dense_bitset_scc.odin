package kosaraju_dense_bitset_scc

import "core:c"

MAX_VERTICES :: 256
MAX_WORDS :: 4
MAX_CELLS :: MAX_VERTICES * MAX_WORDS
MAX_PARSEABLE_INPUT_LENGTH :: 1026

lowest_bit_index :: proc(bits: u64) -> int {
	value := bits
	index := 0
	for (value & 1) == 0 {
		value >>= 1
		index += 1
	}
	return index
}

write_u16_le :: proc(output: [^]u8, position: int, value: u16) {
	output[position] = u8(value & 0xff)
	output[position + 1] = u8(value >> 8)
}

@(export)
kosaraju_dense_bitset_scc :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	if input[0] < 1 || input[0] > i64(MAX_VERTICES) do return -1
	n := int(input[0])
	words := (n + 63) / 64
	if int(length) != 1 + n * words do return -1

	adjacency: [MAX_CELLS]u64
	transpose: [MAX_CELLS]u64
	for cell := 0; cell < n*words; cell += 1 {
		adjacency[cell] = transmute(u64)input[1 + cell]
		transpose[cell] = 0
	}
	if n%64 != 0 {
		valid := (u64(1) << (n % 64)) - 1
		for vertex := 0; vertex < n; vertex += 1 {
			if adjacency[vertex*words+words-1] & ^valid != 0 do return -1
		}
	}
	for source := 0; source < n; source += 1 {
		for word := 0; word < words; word += 1 {
			bits := adjacency[source*words+word]
			for bits != 0 {
				bit := lowest_bit_index(bits)
				target := word*64 + bit
				transpose[target*words+source/64] |= u64(1) << (source % 64)
				bits &= bits - 1
			}
		}
	}

	var unvisited: [MAX_WORDS]u64
	for word := 0; word < words; word += 1 do unvisited[word] = ~u64(0)
	if n%64 != 0 do unvisited[words-1] = (u64(1) << (n % 64)) - 1
	var stack, next_word, order: [MAX_VERTICES]u16
	order_length := 0
	for root := 0; root < n; root += 1 {
		root_word := root / 64
		root_bit := root % 64
		if ((unvisited[root_word] >> root_bit) & 1) == 0 do continue
		unvisited[root_word] &= ~(u64(1) << root_bit)
		stack_length := 1
		stack[0] = u16(root)
		next_word[0] = 0
		for stack_length > 0 {
			depth := stack_length - 1
			vertex := int(stack[depth])
			pushed := false
			for int(next_word[depth]) < words {
				word := int(next_word[depth])
				candidates := adjacency[vertex*words+word] & unvisited[word]
				if candidates != 0 {
					bit := lowest_bit_index(candidates)
					neighbor := word*64 + bit
					unvisited[word] &= ~(u64(1) << bit)
					stack[stack_length] = u16(neighbor)
					next_word[stack_length] = 0
					stack_length += 1
					pushed = true
					break
				}
				next_word[depth] += 1
			}
			if !pushed && int(next_word[depth]) == words {
				order[order_length] = u16(vertex)
				order_length += 1
				stack_length -= 1
			}
		}
	}

	for word := 0; word < words; word += 1 do unvisited[word] = ~u64(0)
	if n%64 != 0 do unvisited[words-1] = (u64(1) << (n % 64)) - 1
	var raw_component: [MAX_VERTICES]u16
	component_count: u16 = 0
	for order_length > 0 {
		order_length -= 1
		root := int(order[order_length])
		root_word := root / 64
		root_bit := root % 64
		if ((unvisited[root_word] >> root_bit) & 1) == 0 do continue
		unvisited[root_word] &= ~(u64(1) << root_bit)
		stack_length := 1
		stack[0] = u16(root)
		raw_component[root] = component_count
		for stack_length > 0 {
			stack_length -= 1
			vertex := int(stack[stack_length])
			for word := 0; word < words; word += 1 {
				candidates := transpose[vertex*words+word] & unvisited[word]
				for candidates != 0 {
					bit := lowest_bit_index(candidates)
					neighbor := word*64 + bit
					selected := u64(1) << bit
					unvisited[word] &= ~selected
					candidates &= ~selected
					raw_component[neighbor] = component_count
					stack[stack_length] = u16(neighbor)
					stack_length += 1
				}
			}
		}
		component_count += 1
	}

	var remap: [MAX_VERTICES]u16
	for component := 0; component < MAX_VERTICES; component += 1 do remap[component] = 0xffff
	canonical_count: u16 = 0
	for vertex := 0; vertex < n; vertex += 1 {
		raw := int(raw_component[vertex])
		if remap[raw] == 0xffff {
			remap[raw] = canonical_count
			canonical_count += 1
		}
	}
	output_length := 2 + 2*n
	if output == nil || output_capacity < c.size_t(output_length) do return -2
	write_u16_le(output, 0, canonical_count)
	for vertex := 0; vertex < n; vertex += 1 do write_u16_le(output, 2+2*vertex, remap[int(raw_component[vertex])])
	return i64(output_length)
}
