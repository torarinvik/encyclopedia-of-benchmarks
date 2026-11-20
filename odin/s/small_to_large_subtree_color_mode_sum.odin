package small_to_large_subtree_color_mode_sum

import "core:c"

MAX_N :: 64
CELLS :: MAX_N * MAX_N

add_color :: proc "contextless" (map, color: int, amount: i64,
    labels: [^]i64, frequencies: [^]i64, keys: [^]int,
    lengths: [^]int, maximum: [^]i64, mode_sum: [^]i64) {
	cell := map * MAX_N + color
	old := frequencies[cell]
	if old == 0 {
		keys[map * MAX_N + lengths[map]] = color
		lengths[map] += 1
	}
	if old > 0 && old == maximum[map] { mode_sum[map] -= labels[color] }
	updated := old + amount
	if updated > maximum[map] {
		maximum[map] = updated
		mode_sum[map] = labels[color]
	} else if updated == maximum[map] {
		mode_sum[map] += labels[color]
	}
	frequencies[cell] = updated
}

put_word :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(byte * 8)) }
}

@(export)
small_to_large_subtree_color_mode_sum :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 129 do return -1
	nv := input[0]
	if nv < 1 || nv > MAX_N || length != c.size_t(2 * nv) do return -1
	n := int(nv)
	var parent: [MAX_N]int
	for vertex := 1; vertex < n; vertex += 1 {
		p := input[vertex]
		if p < 0 || p >= i64(vertex) do return -1
		parent[vertex] = int(p)
	}
	var sorted: [MAX_N]i64
	for vertex := 0; vertex < n; vertex += 1 {
		color := input[n + vertex]
		if color < -1000 || color > 1000 do return -1
		sorted[vertex] = color
	}
	for i := 1; i < n; i += 1 {
		value := sorted[i]
		j := i
		for j > 0 && sorted[j - 1] > value { sorted[j] = sorted[j - 1]; j -= 1 }
		sorted[j] = value
	}
	var labels: [MAX_N]i64
	distinct := 0
	for i := 0; i < n; i += 1 {
		if distinct == 0 || labels[distinct - 1] != sorted[i] {
			labels[distinct] = sorted[i]
			distinct += 1
		}
	}
	var color_index: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 {
		index := 0
		for labels[index] != input[n + vertex] { index += 1 }
		color_index[vertex] = index
	}
	if output == nil || capacity < c.size_t(8 * n) do return -2

	var frequencies: [CELLS]i64
	var keys: [CELLS]int
	var lengths, map_id: [MAX_N]int
	var maximum, mode_sum, answers: [MAX_N]i64
	for vertex := n - 1; vertex >= 0; vertex -= 1 {
		largest := n
		for child := vertex + 1; child < n; child += 1 {
			if parent[child] == vertex &&
				(largest == n || lengths[map_id[child]] > lengths[map_id[largest]]) { largest = child }
		}
		map := vertex
		if largest < n { map = map_id[largest] }
		for child := vertex + 1; child < n; child += 1 {
			if parent[child] != vertex || child == largest { continue }
			small := map_id[child]
			for i := 0; i < lengths[small]; i += 1 {
				color := keys[small * MAX_N + i]
				amount := frequencies[small * MAX_N + color]
				add_color(map, color, amount, &labels[0], &frequencies[0], &keys[0],
					&lengths[0], &maximum[0], &mode_sum[0])
			}
		}
		add_color(map, color_index[vertex], 1, &labels[0], &frequencies[0], &keys[0],
			&lengths[0], &maximum[0], &mode_sum[0])
		map_id[vertex] = map
		answers[vertex] = mode_sum[map]
	}
	for vertex := 0; vertex < n; vertex += 1 { put_word(output, vertex * 8, answers[vertex]) }
	return i64(8 * n)
}
