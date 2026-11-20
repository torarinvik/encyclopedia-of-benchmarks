package bench

VEB_MAX_HEIGHT :: 4
VEB_MAX_NODES :: 15
VEB_MAX_QUERIES :: 4
VEB_MAX_WORDS :: 41
VEB_MAX_PARSEABLE :: 2 + VEB_MAX_QUERIES + 1

veb_fill_keys :: proc(keys: ^[VEB_MAX_NODES + 1]i64, heap: int,
		low, high: i64) {
	if low > high { return }
	middle := low + (high - low) / 2
	keys[heap] = middle
	veb_fill_keys(keys, heap * 2, low, middle - 1)
	veb_fill_keys(keys, heap * 2 + 1, middle + 1, high)
}

veb_emit :: proc(order: ^[VEB_MAX_NODES]i64, used: ^int,
		root, height: int) {
	if height == 1 {
		order[used^] = i64(root)
		used^ += 1
		return
	}
	top_height := height / 2
	bottom_height := height - top_height
	veb_emit(order, used, root, top_height)
	bottom_count := 1 << top_height
	for offset in 0..<bottom_count {
		veb_emit(order, used, root * bottom_count + offset, bottom_height)
	}
}

@(export)
van_emde_boas_layout_search :: proc "c" (input: [^]i64, length: uint,
		output: [^]u8, capacity: uint) -> i64 {
	if input == nil || length < 2 || length > VEB_MAX_PARSEABLE { return -1 }
	height_value := input[0]
	query_value := input[1]
	if height_value < 1 || height_value > i64(VEB_MAX_HEIGHT) ||
		query_value < 0 || query_value > i64(VEB_MAX_QUERIES) { return -1 }
	height := int(height_value)
	query_count := int(query_value)
	if length != uint(2 + query_count) { return -1 }
	node_count := (1 << height) - 1
	for query in 0..<query_count {
		key := input[2 + query]
		if key < -1 || key > i64(node_count) { return -1 }
	}

	order: [VEB_MAX_NODES]i64
	keys: [VEB_MAX_NODES + 1]i64
	slots: [VEB_MAX_NODES + 1]i64
	staged: [VEB_MAX_WORDS]i64
	used := 0
	veb_emit(&order, &used, 1, height)
	veb_fill_keys(&keys, 1, 0, i64(node_count - 1))
	for slot in 0..<node_count { slots[int(order[slot])] = i64(slot) }

	out := 0
	staged[out] = i64(node_count); out += 1
	for slot in 0..<node_count { staged[out] = order[slot]; out += 1 }
	staged[out] = i64(query_count); out += 1
	for query in 0..<query_count {
		key := input[2 + query]
		heap := 1
		path_start := out
		out += 1
		path_length := 0
		found := i64(-1)
		for heap <= node_count {
			staged[out] = slots[heap]; out += 1
			path_length += 1
			if key == keys[heap] { found = i64(heap); break }
			if key < keys[heap] { heap *= 2 } else { heap = heap * 2 + 1 }
		}
		staged[path_start] = i64(path_length)
		staged[out] = found; out += 1
	}
	required := uint(out * 8)
	if output == nil || capacity < required { return -2 }
	for word in 0..<out {
		bits := u64(staged[word])
		for byte in 0..<8 { output[8 * word + byte] = u8((bits >> (8 * byte)) & 0xff) }
	}
	return i64(required)
}
