package bench

HB_GENERATIONS :: 4
HB_BUCKETS :: 8
HB_KEYS :: 32
HB_MAX_OPS :: 64
HB_MAX_WORDS :: 1 + 3 * HB_MAX_OPS + 1
HB_MISS: i64 : -2_147_483_648

hb_find_in_table :: proc(heads, keys, links: [^]i16, table, key: int) -> int {
	node := int(heads[table*HB_BUCKETS + key%HB_BUCKETS])
	for node >= 0 {
		record := table*HB_KEYS + node
		if int(keys[record]) == key { return node }
		node = int(links[record])
	}
	return -1
}

hb_find :: proc(heads, keys, links: [^]i16, newest, key: int, found_table: ^int) -> int {
	for age in 0..<HB_GENERATIONS {
		table := (newest + age) % HB_GENERATIONS
		node := hb_find_in_table(heads, keys, links, table, key)
		if node >= 0 { found_table^ = table; return node }
	}
	found_table^ = -1
	return -1
}

hb_put :: proc(heads, keys, values, links: [^]i16, used: [^]i16,
		newest, key, value: int) {
	node := hb_find_in_table(heads, keys, links, newest, key)
	if node >= 0 {
		values[newest*HB_KEYS + node] = i16(value)
		return
	}
	for node = 0; node < HB_KEYS && keys[newest*HB_KEYS + node] >= 0; node += 1 { }
	if node >= HB_KEYS { return }
	used[newest] += 1
	bucket := key % HB_BUCKETS
	record := newest*HB_KEYS + node
	keys[record] = i16(key)
	values[record] = i16(value)
	links[record] = heads[newest*HB_BUCKETS + bucket]
	heads[newest*HB_BUCKETS + bucket] = i16(node)
}

hb_remove :: proc(heads, keys, values, links: [^]i16, used: [^]i16,
		table, key, target: int) {
	bucket := key % HB_BUCKETS
	previous := -1
	node := int(heads[table*HB_BUCKETS + bucket])
	for node >= 0 && node != target {
		previous = node
		node = int(links[table*HB_KEYS + node])
	}
	if node < 0 { return }
	if previous < 0 { heads[table*HB_BUCKETS + bucket] = links[table*HB_KEYS + node] }
	else { links[table*HB_KEYS + previous] = links[table*HB_KEYS + node] }
	record := table*HB_KEYS + node
	keys[record] = -1
	values[record] = 0
	links[record] = -1
	used[table] -= 1
}

hb_write_i64_le :: proc(output: [^]u8, word: uint, value: i64) {
	bits := u64(value)
	for byte in 0..<8 { output[word*8 + uint(byte)] = u8(bits >> (8*byte)) }
}

@(export)
hashbelt_aging_hash_table :: proc "c" (input: [^]i64, length: uint,
		output: [^]u8, capacity: uint) -> i64 {
	if input == nil || length < 1 || length > HB_MAX_WORDS { return -1 }
	count_value := input[0]
	if count_value < 0 || count_value > HB_MAX_OPS { return -1 }
	count := uint(count_value)
	if length != 1 + 3*count { return -1 }
	for op in 0..<count {
		opcode := input[1 + 3*op]
		key := input[2 + 3*op]
		argument := input[3 + 3*op]
		if opcode == 0 {
			if key < 0 || key >= HB_KEYS || argument < -1000 || argument > 1000 { return -1 }
		} else if opcode == 1 {
			if key < 0 || key >= HB_KEYS || argument != 0 { return -1 }
		} else if opcode == 2 {
			if key != 0 || argument != 0 { return -1 }
		} else { return -1 }
	}
	required := count*8
	if output == nil || capacity < required { return -2 }

	heads: [HB_GENERATIONS*HB_BUCKETS]i16
	keys: [HB_GENERATIONS*HB_KEYS]i16
	values: [HB_GENERATIONS*HB_KEYS]i16
	links: [HB_GENERATIONS*HB_KEYS]i16
	used: [HB_GENERATIONS]i16
	trace: [HB_MAX_OPS]i64
	for index in 0..<HB_GENERATIONS*HB_BUCKETS { heads[index] = -1 }
	for index in 0..<HB_GENERATIONS*HB_KEYS { keys[index] = -1 }
	for index in 0..<HB_GENERATIONS { used[index] = 0 }
	for index in 0..<HB_MAX_OPS { trace[index] = 0 }
	newest := 0
	for op in 0..<count {
		opcode := int(input[1 + 3*op])
		key := int(input[2 + 3*op])
		argument := int(input[3 + 3*op])
		if opcode == 0 {
			found_table := -1
			node := hb_find(&heads[0], &keys[0], &links[0], newest, key, &found_table)
			trace[op] = 1
			if found_table >= 0 { trace[op] = 0 }
			if found_table >= 0 && found_table != newest {
				hb_remove(&heads[0], &keys[0], &values[0], &links[0], &used[0], found_table, key, node)
			}
			hb_put(&heads[0], &keys[0], &values[0], &links[0], &used[0], newest, key, argument)
		} else if opcode == 1 {
			found_table := -1
			node := hb_find(&heads[0], &keys[0], &links[0], newest, key, &found_table)
			if node < 0 { trace[op] = HB_MISS } else {
				trace[op] = i64(values[found_table*HB_KEYS + node])
				if found_table != newest {
					hb_remove(&heads[0], &keys[0], &values[0], &links[0], &used[0], found_table, key, node)
					hb_put(&heads[0], &keys[0], &values[0], &links[0], &used[0], newest, key, int(trace[op]))
				}
			}
		} else {
			oldest := (newest + HB_GENERATIONS - 1) % HB_GENERATIONS
			trace[op] = i64(used[oldest])
			for bucket in 0..<HB_BUCKETS { heads[oldest*HB_BUCKETS + bucket] = -1 }
			for slot in 0..<HB_KEYS { keys[oldest*HB_KEYS + slot] = -1 }
			used[oldest] = 0
			newest = oldest
		}
	}
	for op in 0..<count { hb_write_i64_le(output, op, trace[op]) }
	return i64(required)
}
