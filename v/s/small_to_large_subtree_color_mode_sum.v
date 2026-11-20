module small_to_large_subtree_color_mode_sum

const max_n = 64
const cells = max_n * max_n

fn stlm_add_color(map int, color int, amount i64, labels &i64,
	mut frequencies &i64, mut keys &int, mut lengths &int,
	mut maximum &i64, mut mode_sum &i64) {
	unsafe {
		cell := map * max_n + color
		old := frequencies[cell]
		if old == 0 {
			keys[map * max_n + lengths[map]] = color
			lengths[map]++
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
}

fn stlm_put_word(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'small_to_large_subtree_color_mode_sum']
pub fn small_to_large_subtree_color_mode_sum(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 129 { return -1 }
	unsafe {
		nv := input[0]
		if nv < 1 || nv > max_n || length != usize(2 * nv) { return -1 }
		n := int(nv)
		mut parent := [max_n]int{}
		for vertex in 1 .. n {
			p := input[vertex]
			if p < 0 || p >= i64(vertex) { return -1 }
			parent[vertex] = int(p)
		}
		mut sorted := [max_n]i64{}
		for vertex in 0 .. n {
			color := input[n + vertex]
			if color < -1000 || color > 1000 { return -1 }
			sorted[vertex] = color
		}
		for i in 1 .. n {
			value := sorted[i]
			mut j := i
			for j > 0 && sorted[j - 1] > value { sorted[j] = sorted[j - 1]; j-- }
			sorted[j] = value
		}
		mut labels := [max_n]i64{}
		mut distinct := 0
		for i in 0 .. n {
			if distinct == 0 || labels[distinct - 1] != sorted[i] {
				labels[distinct] = sorted[i]
				distinct++
			}
		}
		mut color_index := [max_n]int{}
		for vertex in 0 .. n {
			mut index := 0
			for labels[index] != input[n + vertex] { index++ }
			color_index[vertex] = index
		}
		if unsafe { output == nil } || capacity < usize(8 * n) { return -2 }

		mut frequencies := [cells]i64{}
		mut keys := [cells]int{}
		mut lengths := [max_n]int{}
		mut map_id := [max_n]int{}
		mut maximum := [max_n]i64{}
		mut mode_sum := [max_n]i64{}
		mut answers := [max_n]i64{}
		mut vertex := n - 1
		for vertex >= 0 {
			mut largest := n
			for child in vertex + 1 .. n {
				if parent[child] == vertex &&
					(largest == n || lengths[map_id[child]] > lengths[map_id[largest]]) { largest = child }
			}
			mut map := vertex
			if largest < n { map = map_id[largest] }
			for child in vertex + 1 .. n {
				if parent[child] != vertex || child == largest { continue }
				small := map_id[child]
				for i in 0 .. lengths[small] {
					color := keys[small * max_n + i]
					amount := frequencies[small * max_n + color]
					stlm_add_color(map, color, amount, &labels[0], &frequencies[0], &keys[0],
						&lengths[0], &maximum[0], &mode_sum[0])
				}
			}
			stlm_add_color(map, color_index[vertex], 1, &labels[0], &frequencies[0], &keys[0],
				&lengths[0], &maximum[0], &mode_sum[0])
			map_id[vertex] = map
			answers[vertex] = mode_sum[map]
			vertex--
		}
		for vertex in 0 .. n { stlm_put_word(&output[0], vertex * 8, answers[vertex]) }
		return i64(8 * n)
	}
}
