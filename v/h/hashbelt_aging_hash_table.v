const hb_generations = 4
const hb_buckets = 8
const hb_keys = 32
const hb_max_operations = 64
const hb_max_words = 1 + 3 * hb_max_operations + 1
const hb_miss = i64(-2147483648)

fn hb_find_in_table(heads []i16, keys []i16, links []i16, table int, key int) int {
	mut node := int(heads[table * hb_buckets + key % hb_buckets])
	for node >= 0 {
		record := table * hb_keys + node
		if int(keys[record]) == key { return node }
		node = int(links[record])
	}
	return -1
}

fn hb_find(heads []i16, keys []i16, links []i16, newest int, key int) (int, int) {
	for age in 0 .. hb_generations {
		table := (newest + age) % hb_generations
		node := hb_find_in_table(heads, keys, links, table, key)
		if node >= 0 { return table, node }
	}
	return -1, -1
}

fn hb_put(mut heads []i16, mut keys []i16, mut values []i16, mut links []i16,
		mut used []i16, newest int, key int, value int) {
	mut node := hb_find_in_table(heads, keys, links, newest, key)
	if node >= 0 {
		values[newest * hb_keys + node] = i16(value)
		return
	}
	mut fresh := -1
	for slot in 0 .. hb_keys {
		if keys[newest * hb_keys + slot] < 0 {
			fresh = slot
			break
		}
	}
	if fresh < 0 { return }
	node = fresh
	used[newest]++
	bucket := key % hb_buckets
	record := newest * hb_keys + node
	keys[record] = i16(key)
	values[record] = i16(value)
	links[record] = heads[newest * hb_buckets + bucket]
	heads[newest * hb_buckets + bucket] = i16(node)
}

fn hb_remove(mut heads []i16, mut keys []i16, mut values []i16, mut links []i16,
		mut used []i16, table int, key int, target int) {
	bucket := key % hb_buckets
	mut previous := -1
	mut node := int(heads[table * hb_buckets + bucket])
	for node >= 0 && node != target {
		previous = node
		node = int(links[table * hb_keys + node])
	}
	if node < 0 { return }
	if previous < 0 { heads[table * hb_buckets + bucket] = links[table * hb_keys + node] }
	else { links[table * hb_keys + previous] = links[table * hb_keys + node] }
	record := table * hb_keys + node
	keys[record] = -1
	values[record] = 0
	links[record] = -1
	used[table]--
}

fn hb_write(output &u8, word int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[word * 8 + byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'hashbelt_aging_hash_table']
pub fn hashbelt_aging_hash_table(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > hb_max_words { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 0 || count_value > hb_max_operations { return -1 }
	count := int(count_value)
	if length != usize(1 + 3 * count) { return -1 }
	for op in 0 .. count {
		opcode := unsafe { input[1 + 3 * op] }
		key := unsafe { input[2 + 3 * op] }
		argument := unsafe { input[3 + 3 * op] }
		if opcode == 0 {
			if key < 0 || key >= hb_keys || argument < -1000 || argument > 1000 { return -1 }
		} else if opcode == 1 {
			if key < 0 || key >= hb_keys || argument != 0 { return -1 }
		} else if opcode == 2 {
			if key != 0 || argument != 0 { return -1 }
		} else { return -1 }
	}
	required := count * 8
	if unsafe { output == nil } || capacity < usize(required) { return -2 }

	mut heads := [32]i16{}
	mut keys := [128]i16{}
	mut values := [128]i16{}
	mut links := [128]i16{}
	mut used := [4]i16{}
	mut trace := [64]i64{}
	for index in 0 .. 32 { heads[index] = -1 }
	for index in 0 .. 128 { keys[index] = -1 }
	mut newest := 0
	for op in 0 .. count {
		opcode := int(unsafe { input[1 + 3 * op] })
		key := int(unsafe { input[2 + 3 * op] })
		argument := int(unsafe { input[3 + 3 * op] })
		if opcode == 0 {
			found_table, node := hb_find(heads[..], keys[..], links[..], newest, key)
			trace[op] = if found_table < 0 { 1 } else { 0 }
			if found_table >= 0 && found_table != newest {
				hb_remove(mut heads[..], mut keys[..], mut values[..], mut links[..], mut used[..], found_table, key, node)
			}
			hb_put(mut heads[..], mut keys[..], mut values[..], mut links[..], mut used[..], newest, key, argument)
		} else if opcode == 1 {
			found_table, node := hb_find(heads[..], keys[..], links[..], newest, key)
			if node < 0 {
				trace[op] = hb_miss
			} else {
				trace[op] = i64(values[found_table * hb_keys + node])
				if found_table != newest {
					hb_remove(mut heads[..], mut keys[..], mut values[..], mut links[..], mut used[..], found_table, key, node)
					hb_put(mut heads[..], mut keys[..], mut values[..], mut links[..], mut used[..], newest, key, int(trace[op]))
				}
			}
		} else {
			oldest := (newest + hb_generations - 1) % hb_generations
			trace[op] = i64(used[oldest])
			for bucket in 0 .. hb_buckets { heads[oldest * hb_buckets + bucket] = -1 }
			for slot in 0 .. hb_keys { keys[oldest * hb_keys + slot] = -1 }
			used[oldest] = 0
			newest = oldest
		}
	}
	for op in 0 .. count { hb_write(output, op, trace[op]) }
	return i64(required)
}
