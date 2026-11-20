module kosaraju_dense_bitset_scc

const max_vertices = 256
const max_words = 4
const max_cells = max_vertices * max_words
const max_parseable_input_length = 1026

fn lowest_bit_index(bits u64) int {
	mut value := bits
	mut index := 0
	for (value & u64(1)) == 0 {
		value >>= 1
		index++
	}
	return index
}

fn write_u16_le(mut output &u8, position int, value u16) {
	unsafe {
		output[position] = u8(value & u16(0xff))
		output[position + 1] = u8(value >> 8)
	}
}

@[export: 'kosaraju_dense_bitset_scc']
pub fn kosaraju_dense_bitset_scc(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_input_length { return -1 }
		if input[0] < 1 || input[0] > i64(max_vertices) { return -1 }
		n := int(input[0])
		words := (n + 63) / 64
		if int(length) != 1 + n*words { return -1 }

		mut adjacency := []u64{len: max_cells, init: 0}
		mut transpose := []u64{len: max_cells, init: 0}
		for cell in 0 .. n * words { adjacency[cell] = u64(input[1 + cell]) }
		if n % 64 != 0 {
			valid := (u64(1) << (n % 64)) - u64(1)
			for vertex in 0 .. n {
				if adjacency[vertex*words+words-1] & ~valid != 0 { return -1 }
			}
		}
		for source in 0 .. n {
			for word in 0 .. words {
				mut bits := adjacency[source*words+word]
				for bits != 0 {
					bit := lowest_bit_index(bits)
					target := word*64 + bit
					transpose[target*words+source/64] |= u64(1) << (source % 64)
					bits &= bits - u64(1)
				}
			}
		}

		mut unvisited := []u64{len: max_words, init: 0}
		for word in 0 .. words { unvisited[word] = ~u64(0) }
		if n % 64 != 0 { unvisited[words-1] = (u64(1) << (n % 64)) - u64(1) }
		mut stack := []u16{len: max_vertices, init: 0}
		mut next_word := []u16{len: max_vertices, init: 0}
		mut order := []u16{len: max_vertices, init: 0}
		mut order_length := 0
		for root in 0 .. n {
			root_word := root / 64
			root_bit := root % 64
			if ((unvisited[root_word] >> root_bit) & u64(1)) == 0 { continue }
			unvisited[root_word] &= ~(u64(1) << root_bit)
			mut stack_length := 1
			stack[0] = u16(root)
			next_word[0] = 0
			for stack_length > 0 {
				depth := stack_length - 1
				vertex := int(stack[depth])
				mut pushed := false
				for int(next_word[depth]) < words {
					word := int(next_word[depth])
					candidates := adjacency[vertex*words+word] & unvisited[word]
					if candidates != 0 {
						bit := lowest_bit_index(candidates)
						neighbor := word*64 + bit
						unvisited[word] &= ~(u64(1) << bit)
						stack[stack_length] = u16(neighbor)
						next_word[stack_length] = 0
						stack_length++
						pushed = true
						break
					}
					next_word[depth]++
				}
				if !pushed && int(next_word[depth]) == words {
					order[order_length] = u16(vertex)
					order_length++
					stack_length--
				}
			}
		}

		for word in 0 .. words { unvisited[word] = ~u64(0) }
		if n % 64 != 0 { unvisited[words-1] = (u64(1) << (n % 64)) - u64(1) }
		mut raw_component := []u16{len: max_vertices, init: 0}
		mut component_count := u16(0)
		for order_length > 0 {
			order_length--
			root := int(order[order_length])
			root_word := root / 64
			root_bit := root % 64
			if ((unvisited[root_word] >> root_bit) & u64(1)) == 0 { continue }
			unvisited[root_word] &= ~(u64(1) << root_bit)
			mut stack_length := 1
			stack[0] = u16(root)
			raw_component[root] = component_count
			for stack_length > 0 {
				stack_length--
				vertex := int(stack[stack_length])
				for word in 0 .. words {
					mut candidates := transpose[vertex*words+word] & unvisited[word]
					for candidates != 0 {
						bit := lowest_bit_index(candidates)
						neighbor := word*64 + bit
						selected := u64(1) << bit
						unvisited[word] &= ~selected
						candidates &= ~selected
						raw_component[neighbor] = component_count
						stack[stack_length] = u16(neighbor)
						stack_length++
					}
				}
			}
			component_count++
		}

		mut remap := []u16{len: max_vertices, init: u16(0xffff)}
		mut canonical_count := u16(0)
		for vertex in 0 .. n {
			raw := int(raw_component[vertex])
			if remap[raw] == u16(0xffff) {
				remap[raw] = canonical_count
				canonical_count++
			}
		}
		output_length := 2 + 2*n
		if output == nil || output_capacity < usize(output_length) { return -2 }
		write_u16_le(mut output, 0, canonical_count)
		for vertex in 0 .. n { write_u16_le(mut output, 2+2*vertex, remap[int(raw_component[vertex])]) }
		return i64(output_length)
	}
}
