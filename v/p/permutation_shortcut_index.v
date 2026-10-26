module permutation_shortcut_index

const max_n = 16
const max_queries = 16
const max_input = 52

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

fn is_marked(bitmap u32, vertex int) bool {
	return (bitmap & (u32(1) << u32(vertex))) != 0
}

fn shortcut_inverse(target int, n int, successor &int, bitmap u32, shortcuts &int) int {
	mut marker := target
	mut steps := 0
	for steps < n && !is_marked(bitmap, marker) {
		marker = successor[marker]
		steps++
	}
	if !is_marked(bitmap, marker) {
		mut previous := target
		mut current := successor[target]
		for current != target { previous = current; current = successor[current] }
		return previous
	}
	mut rank := 0
	for vertex in 0 .. marker { if is_marked(bitmap, vertex) { rank++ } }
	mut current := shortcuts[rank]
	mut previous := current
	current = successor[current]
	mut walked := 0
	for walked < n {
		if current == target { return previous }
		previous = current
		current = successor[current]
		walked++
	}
	return -1
}

pub fn permutation_shortcut_index(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == unsafe { nil } || length < 4 || length > max_input { return -1 }
	n_raw := input[0]
	stride_raw := input[1]
	if n_raw < 1 || n_raw > max_n || stride_raw < 1 || stride_raw > max_n { return -1 }
	n := int(n_raw)
	stride := int(stride_raw)
	query_at := 2 + n
	if length <= usize(query_at) { return -1 }
	query_raw := input[query_at]
	if query_raw < 0 || query_raw > max_queries || length != usize(query_at + 1 + 2 * int(query_raw)) { return -1 }
	query_count := int(query_raw)
	mut successor := [max_n]int{}
	mut seen := [max_n]bool{}
	for vertex in 0 .. n {
		value := input[2 + vertex]
		if value < 1 || value > n_raw || seen[int(value - 1)] { return -1 }
		seen[int(value - 1)] = true
		successor[vertex] = int(value - 1)
	}
	for query in 0 .. query_count {
		op := input[query_at + 1 + 2 * query]
		index := input[query_at + 2 + 2 * query]
		if (op != 0 && op != 1) || index < 1 || index > n_raw { return -1 }
	}
	mut visited := [max_n]bool{}
	mut back_pointer := [max_n]int{}
	for vertex in 0 .. n { back_pointer[vertex] = -1 }
	mut bitmap := u32(0)
	for start in 0 .. n {
		if visited[start] { continue }
		mut cycle := [max_n]int{}
		mut cycle_length := 0
		mut current := start
		for !visited[current] {
			visited[current] = true
			cycle[cycle_length] = current
			cycle_length++
			current = successor[current]
		}
		if cycle_length >= stride {
			mut offset := 0
			for offset < cycle_length {
				vertex := cycle[offset]
				bitmap |= u32(1) << u32(vertex)
				mut back_offset := (offset - stride) % cycle_length
				if back_offset < 0 { back_offset += cycle_length }
				back_pointer[vertex] = cycle[back_offset]
				offset += stride
			}
		}
	}
	mut shortcuts := [max_n]int{}
	mut shortcut_count := 0
	for vertex in 0 .. n {
		if is_marked(bitmap, vertex) { shortcuts[shortcut_count] = back_pointer[vertex]; shortcut_count++ }
	}
	mut answers := [max_queries]i64{}
	for query in 0 .. query_count {
		op := input[query_at + 1 + 2 * query]
		target := int(input[query_at + 2 + 2 * query]) - 1
		answer := if op == 0 { successor[target] } else { shortcut_inverse(target, n, &successor[0], bitmap, &shortcuts[0]) }
		if answer < 0 { return -1 }
		answers[query] = i64(answer + 1)
	}
	bytes := query_count * 8
	if output == unsafe { nil } || capacity < usize(bytes) { return -2 }
	mut staged := []u8{len: bytes, init: 0}
	for query in 0 .. query_count { store_i64_le(mut staged, query * 8, answers[query]) }
	for byte in 0 .. bytes { output[byte] = staged[byte] }
	return i64(bytes)
}
