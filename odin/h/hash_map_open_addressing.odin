package hash_map_open_addressing

import "core:c"

MAX_OPERATIONS :: 256
MAX_KEYS :: 64
MAX_CAPACITY :: 1024
MAX_INPUT_LENGTH :: 769
VALUE_OFFSET :: i64(1_000_001)

Entry :: struct { state: int, key: i64, value: i64 }

place :: proc(table: [^]Entry, capacity: int, key, value: i64) {
	index := int(key % i64(capacity))
	for _ in 0..<capacity {
		if table[index].state != 1 { table[index] = Entry{1, key, value}; return }
		if table[index].key == key { table[index].value = value; return }
		index = (index + 1) % capacity
	}
}

resize_table :: proc(table: [^]Entry, capacity: ^int, next: int, size: ^int) {
	old: [MAX_CAPACITY]Entry
	old_capacity := capacity^
	for i in 0..<old_capacity { old[i] = table[i] }
	for i in 0..<next { table[i] = Entry{} }
	capacity^ = next
	size^ = 0
	for i in 0..<old_capacity {
		if old[i].state == 1 { place(table, next, old[i].key, old[i].value); size^ += 1 }
	}
}

Find :: struct { found: int, tombstone: int, tomb_before: bool }
find_key :: proc(table: [^]Entry, capacity: int, key: i64) -> Find {
	index := int(key % i64(capacity))
	tombstone := capacity
	for _ in 0..<capacity {
		if table[index].state == 0 { return Find{capacity, tombstone, false} }
		if table[index].state == 2 {
			if tombstone == capacity { tombstone = index }
		} else if table[index].key == key {
			return Find{index, tombstone, tombstone != capacity}
		}
		index = (index + 1) % capacity
	}
	return Find{capacity, tombstone, false}
}

@(export)
hash_map_open_addressing :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	q := values[0]
	if q < 0 || q > MAX_OPERATIONS || length != c.size_t(1 + 3 * q) do return -1
	table: [MAX_CAPACITY]Entry
	capacity := 8
	size := 0
	query_sum: i64 = 0
	query_index: i64 = 0
	for opi in 0..<int(q) {
		opcode := values[1 + 3*opi]
		key := values[2 + 3*opi]
		value := values[3 + 3*opi]
		if opcode == 0 {
			if key < 0 || key > 1_000_000 || value < -1_000_000 || value > 1_000_000 do return -1
			before := find_key(&table[0], capacity, key)
			if before.found == capacity && size >= MAX_KEYS do return -1
			if size >= capacity * 3 / 4 {
				if capacity * 2 > MAX_CAPACITY do return -1
				resize_table(&table[0], &capacity, capacity * 2, &size)
			}
			found := find_key(&table[0], capacity, key)
			if found.found != capacity {
				if found.tomb_before do return -1
				table[found.found].value = value
			} else {
				index := int(key % i64(capacity))
				target := found.tombstone
				for _ in 0..<capacity {
					if table[index].state == 0 { if target == capacity { target = index }; break }
					index = (index + 1) % capacity
				}
				if target == capacity do return -1
				table[target] = Entry{1, key, value}
				size += 1
			}
		} else if opcode == 1 || opcode == 2 || opcode == 3 {
			if key < 0 || key > 1_000_000 || value != 0 do return -1
			found := find_key(&table[0], capacity, key)
			if (opcode == 1 || opcode == 2) && found.found == capacity do return -1
			if opcode == 1 {
				query_index += 1
				query_sum += query_index * (table[found.found].value + VALUE_OFFSET)
			} else if opcode == 2 {
				table[found.found].state = 2
				size -= 1
				if capacity > 8 && size < capacity * 3 / 8 { resize_table(&table[0], &capacity, capacity / 2, &size) }
			} else {
				query_index += 1
				present: i64 = 0
				if found.found != capacity { present = 1 }
				query_sum += query_index * (present + VALUE_OFFSET)
			}
		} else if opcode == 4 {
			if key != 0 || value != 0 do return -1
			query_index += 1
			query_sum += query_index * (i64(size) + VALUE_OFFSET)
		} else do return -1
	}
	keys: [MAX_KEYS]i64
	vals: [MAX_KEYS]i64
	count := 0
	for i in 0..<capacity {
		if table[i].state == 1 {
			at := count
			count += 1
			for at > 0 && keys[at-1] > table[i].key { keys[at] = keys[at-1]; vals[at] = vals[at-1]; at -= 1 }
			keys[at] = table[i].key
			vals[at] = table[i].value
		}
	}
	final_state: i64 = 0
	for i in 0..<count { final_state += i64(i+1) * (keys[i]+1) * (vals[i]+VALUE_OFFSET) }
	return query_sum + final_state + i64(size)
}
