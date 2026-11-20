const veb_max_height = 4
const veb_max_nodes = 15
const veb_max_queries = 4
const veb_max_words = 41
const veb_max_parseable = 2 + veb_max_queries + 1

fn veb_fill_keys(mut keys []i64, heap int, low i64, high i64) {
	if low > high { return }
	middle := low + (high - low) / 2
	keys[heap] = middle
	veb_fill_keys(mut keys, heap * 2, low, middle - 1)
	veb_fill_keys(mut keys, heap * 2 + 1, middle + 1, high)
}

fn veb_emit(mut order []i64, mut used int, root int, height int) {
	if height == 1 {
		order[used] = i64(root)
		used++
		return
	}
	top_height := height / 2
	bottom_height := height - top_height
	veb_emit(mut order, mut used, root, top_height)
	bottom_count := 1 << top_height
	for offset in 0 .. bottom_count {
		veb_emit(mut order, mut used, root * bottom_count + offset, bottom_height)
	}
}

@[export: 'van_emde_boas_layout_search']
pub fn van_emde_boas_layout_search(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > veb_max_parseable { return -1 }
	height_value := unsafe { input[0] }
	query_value := unsafe { input[1] }
	if height_value < 1 || height_value > i64(veb_max_height) ||
		query_value < 0 || query_value > i64(veb_max_queries) { return -1 }
	height := int(height_value)
	query_count := int(query_value)
	if length != usize(2 + query_count) { return -1 }
	node_count := (1 << height) - 1
	for query in 0 .. query_count {
		key := unsafe { input[2 + query] }
		if key < -1 || key > i64(node_count) { return -1 }
	}

	mut order := [veb_max_nodes]i64{}
	mut keys := [veb_max_nodes + 1]i64{}
	mut slots := [veb_max_nodes + 1]i64{}
	mut staged := [veb_max_words]i64{}
	mut used := 0
	veb_emit(mut order[..], mut used, 1, height)
	veb_fill_keys(mut keys[..], 1, 0, i64(node_count - 1))
	for slot in 0 .. node_count { slots[int(order[slot])] = i64(slot) }

	mut out := 0
	staged[out] = i64(node_count)
	out++
	for slot in 0 .. node_count { staged[out] = order[slot]; out++ }
	staged[out] = i64(query_count)
	out++
	for query in 0 .. query_count {
		key := unsafe { input[2 + query] }
		mut heap := 1
		path_start := out
		out++
		mut path_length := 0
		mut found := i64(-1)
		for heap <= node_count {
			staged[out] = slots[heap]
			out++
			path_length++
			if key == keys[heap] { found = i64(heap); break }
			if key < keys[heap] { heap *= 2 } else { heap = heap * 2 + 1 }
		}
		staged[path_start] = i64(path_length)
		staged[out] = found
		out++
	}
	required := out * 8
	if unsafe { output == nil } || capacity < usize(required) { return -2 }
	for word in 0 .. out {
		bits := u64(staged[word])
		for byte in 0 .. 8 {
			unsafe { output[8 * word + byte] = u8(bits >> (8 * byte)) }
		}
	}
	return i64(required)
}
