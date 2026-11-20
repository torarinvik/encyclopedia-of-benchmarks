module signed_permutation_overlap_forest_components

import c

const max_n = 8
const max_vertices = 2 * max_n + 2
const max_cycles = max_n + 1
const max_input = max_n + 2
const max_output_words = 1 + 3 * max_cycles
const max_output = 8 * max_output_words

fn store_word(mut bytes []u8, word int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { bytes[word*8+byte] = u8((bits >> (8*byte)) & 255) }
}

@[export: 'signed_permutation_overlap_forest_components']
pub fn signed_permutation_overlap_forest_components(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n_value := input[0]
		if n_value < 1 || n_value > max_n || length != usize(n_value+1) { return -1 }
		n, vertex_count := int(n_value), int(2*n_value+2)
		mut pi := []int{len: max_vertices, init: 0}
		pi[vertex_count-1] = vertex_count-1
		mut seen := u16(0)
		for position in 0 .. n {
			gene := input[position+1]
			if gene == 0 || gene < -n_value || gene > n_value { return -1 }
			absolute := int(if gene < 0 { -gene } else { gene })
			bit := u16(1 << (absolute-1))
			if seen & bit != 0 { return -1 }
			seen |= bit
			mut left, mut right := 2*absolute-1, 2*absolute
			if gene < 0 { left, right = right, left }
			pi[2*position+1], pi[2*position+2] = left, right
		}
		mut gray := []int{len: max_vertices, init: 0}
		for pair in 0 .. n+1 {
			left, right := pi[2*pair], pi[2*pair+1]
			gray[left], gray[right] = right, left
		}
		mut cycle_of := []int{len: max_vertices, init: -1}
		mut begin, mut end := []int{len: max_cycles, init: 0}, []int{len: max_cycles, init: 0}
		mut cycle_count := 0
		for seed in 0 .. vertex_count {
			if cycle_of[seed] >= 0 { continue }
			cid := cycle_count
			cycle_count++
			mut vertex, mut low, mut high := seed, seed, seed
			for cycle_of[vertex] < 0 {
				cycle_of[vertex] = cid
				if vertex < low { low = vertex }
				if vertex > high { high = vertex }
				vertex = gray[vertex ^ 1]
			}
			begin[cid], end[cid] = low, high
		}
		mut parent := []int{len: max_cycles, init: 0}
		for cid in 0 .. cycle_count { parent[cid] = cid }
		mut stack_id, mut stack_begin, mut stack_end :=
			[]int{len: max_cycles, init: 0}, []int{len: max_cycles, init: 0}, []int{len: max_cycles, init: 0}
		mut top := 0
		for vertex in 0 .. vertex_count {
			cid := cycle_of[vertex]
			low, high := begin[cid], end[cid]
			if vertex == low {
				stack_id[top], stack_begin[top], stack_end[top] = cid, low, high
				top++
			}
			mut extent_begin, mut extent_end := low, high
			for top > 0 && stack_begin[top-1] > low {
				top--
				popped := stack_id[top]
				if stack_begin[top] < extent_begin { extent_begin = stack_begin[top] }
				if stack_end[top] > extent_end { extent_end = stack_end[top] }
				parent[popped] = cid
			}
			if top == 0 { return -1 }
			if extent_begin < stack_begin[top-1] { stack_begin[top-1] = extent_begin }
			if extent_end > stack_end[top-1] { stack_end[top-1] = extent_end }
			if vertex == stack_end[top-1] { top-- }
		}
		mut component := []int{len: max_cycles, init: 0}
		for cid in 0 .. cycle_count {
			if parent[cid] == cid { component[cid] = begin[cid] }
			else { component[cid] = component[parent[cid]] }
		}
		mut words := []i64{len: max_output_words, init: 0}
		words[0] = i64(cycle_count)
		for cid in 0 .. cycle_count {
			words[1+3*cid], words[2+3*cid], words[3+3*cid] =
				i64(begin[cid]), i64(end[cid]), i64(component[cid])
		}
		output_bytes := (1+3*cycle_count)*8
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := []u8{len: max_output, init: 0}
		for word in 0 .. 1+3*cycle_count { store_word(mut staged, word, words[word]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
