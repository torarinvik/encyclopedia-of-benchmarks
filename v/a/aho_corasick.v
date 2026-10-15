module aho_corasick

const max_patterns = 16
const max_pattern_length = 32
const max_text_length = 256
const max_nodes = 1 + max_patterns * max_pattern_length

fn find_transition(first_edge []int, edge_next []int, edge_character []int,
	edge_target []int, state int, character int) int {
	mut edge := first_edge[state]
	for edge != 0 {
		index := edge - 1
		if edge_character[index] == character { return edge_target[index] }
		edge = edge_next[index]
	}
	return -1
}

@[export: 'aho_corasick']
pub fn aho_corasick(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 3 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_patterns || input[1] < 0 || input[1] > max_text_length { return -1 }
		pattern_count := int(input[0])
		if length < usize(2 + pattern_count) { return -1 }
		mut starts := [max_patterns]int{}
		mut text_start := 2 + pattern_count
		for p in 0 .. pattern_count {
			if input[2 + p] < 1 || input[2 + p] > max_pattern_length { return -1 }
			size := int(input[2 + p])
			if text_start + size > int(length) { return -1 }
			starts[p] = text_start
			for i in 0 .. size { if input[starts[p] + i] < 1 || input[starts[p] + i] > 127 { return -1 } }
			for q in 0 .. p {
				if int(input[2 + q]) != size { continue }
				mut i := 0
				for i < size && input[starts[q] + i] == input[starts[p] + i] { i++ }
				if i == size { return -1 }
			}
			text_start += size
		}
		text_length := int(input[1])
		if text_start + text_length != int(length) { return -1 }
		for i in 0 .. text_length { if input[text_start + i] < 1 || input[text_start + i] > 127 { return -1 } }
		output_size := pattern_count * 8
		if output_capacity < usize(output_size) || output == nil { return -2 }

		mut first_edge := [max_nodes]int{}
		mut edge_next := [max_nodes]int{}
		mut edge_character := [max_nodes]int{}
		mut edge_target := [max_nodes]int{}
		mut failure := [max_nodes]int{}
		mut terminal := [max_nodes]int{}
		mut queue := [max_nodes]int{}
		for n in 0 .. max_nodes { terminal[n] = -1 }
		mut edge_count := 0
		mut nodes := 1
		for p in 0 .. pattern_count {
			mut state := 0
			for i in 0 .. int(input[2 + p]) {
				ch := int(input[starts[p] + i])
				mut target := find_transition(first_edge[..], edge_next[..], edge_character[..], edge_target[..], state, ch)
				if target == -1 {
					if edge_count >= max_nodes { return -1 }
					target = nodes
					edge_next[edge_count] = first_edge[state]
					edge_character[edge_count] = ch
					edge_target[edge_count] = target
					first_edge[state] = edge_count + 1
					edge_count++
					nodes++
				}
				state = target
			}
			terminal[state] = p
		}

		mut head := 0
		mut tail := 0
		mut edge := first_edge[0]
		for edge != 0 {
			index := edge - 1
			queue[tail] = edge_target[index]
			tail++
			edge = edge_next[index]
		}
		for head < tail {
			state := queue[head]
			head++
			edge = first_edge[state]
			for edge != 0 {
				index := edge - 1
				ch := edge_character[index]
				child := edge_target[index]
				mut suffix := failure[state]
				mut suffix_transition := find_transition(first_edge[..], edge_next[..], edge_character[..], edge_target[..], suffix, ch)
				for suffix != 0 && suffix_transition == -1 {
					suffix = failure[suffix]
					suffix_transition = find_transition(first_edge[..], edge_next[..], edge_character[..], edge_target[..], suffix, ch)
				}
				if suffix_transition != -1 { suffix = suffix_transition }
				failure[child] = suffix
				queue[tail] = child
				tail++
				edge = edge_next[index]
			}
		}

		mut counts := [max_patterns]i64{}
		mut state := 0
		for i in 0 .. text_length {
			ch := int(input[text_start + i])
			mut transition := find_transition(first_edge[..], edge_next[..], edge_character[..], edge_target[..], state, ch)
			for state != 0 && transition == -1 {
				state = failure[state]
				transition = find_transition(first_edge[..], edge_next[..], edge_character[..], edge_target[..], state, ch)
			}
			if transition != -1 { state = transition }
			mut matched := state
			for matched != 0 {
				if terminal[matched] >= 0 { counts[terminal[matched]]++ }
				matched = failure[matched]
			}
		}
		for p in 0 .. pattern_count {
			for b in 0 .. 8 { output[p * 8 + b] = u8((counts[p] >> (8 * b)) & 255) }
		}
		return i64(output_size)
	}
}
