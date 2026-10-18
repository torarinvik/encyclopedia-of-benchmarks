package robin_hood_hash

import "core:c"

TABLE_CAPACITY :: 16
MAX_ACTIVE_ENTRIES :: 14
MAX_OPERATIONS :: 64
MAX_INPUT_LENGTH :: 1 + 3 * MAX_OPERATIONS
MAX_OUTPUT_BYTES :: 8 * MAX_OPERATIONS
MAX_PROBE_DISTANCE :: u32(64)
GOLDEN_RATIO :: u64(0x9E3779B97F4A7C15)

Entry :: struct { key: u32, value: u32, psl: u32, occupied: bool }
RobinHoodMap :: struct { entries: [TABLE_CAPACITY]Entry, count: int }

hash_key :: proc "contextless" (key: u32) -> int {
	product := u64(key) *% GOLDEN_RATIO
	return int((product >> 32) & u64(TABLE_CAPACITY - 1))
}

map_put :: proc "contextless" (map: ^RobinHoodMap, key, value: u32) -> bool {
	if (map.count * 100) / TABLE_CAPACITY >= 90 do return false
	entry := Entry{key = key, value = value, psl = 0, occupied = true}
	index := hash_key(key)
	probes := u32(0)
	for probes < MAX_PROBE_DISTANCE {
		resident := &map.entries[index]
		if !resident.occupied {
			resident^ = entry
			map.count += 1
			return true
		}
		if resident.key == key { resident.value = value; return true }
		if entry.psl > resident.psl { temp := resident^; resident^ = entry; entry = temp }
		entry.psl += 1
		index = (index + 1) & (TABLE_CAPACITY - 1)
		probes += 1
	}
	return false
}

map_get :: proc "contextless" (map: ^RobinHoodMap, key: u32) -> i64 {
	index := hash_key(key)
	psl := u32(0)
	for psl < MAX_PROBE_DISTANCE {
		resident := map.entries[index]
		if !resident.occupied do return -1
		if resident.key == key do return i64(resident.value)
		if psl > resident.psl do return -1
		index = (index + 1) & (TABLE_CAPACITY - 1)
		psl += 1
	}
	return -1
}

map_backshift :: proc "contextless" (map: ^RobinHoodMap, start: int) {
	index := start
	for iteration := 0; iteration < TABLE_CAPACITY; iteration += 1 {
		next := (index + 1) & (TABLE_CAPACITY - 1)
		if !map.entries[next].occupied || map.entries[next].psl == 0 {
			map.entries[index].occupied = false
			map.entries[index].psl = 0
			return
		}
		map.entries[index] = map.entries[next]
		map.entries[index].psl -= 1
		index = next
	}
}

map_remove :: proc "contextless" (map: ^RobinHoodMap, key: u32) -> bool {
	index := hash_key(key)
	psl := u32(0)
	for psl < MAX_PROBE_DISTANCE {
		resident := &map.entries[index]
		if !resident.occupied do return false
		if resident.key == key {
			map_backshift(map, index)
			map.count -= 1
			return true
		}
		if psl > resident.psl do return false
		index = (index + 1) & (TABLE_CAPACITY - 1)
		psl += 1
	}
	return false
}

map_clear :: proc "contextless" (map: ^RobinHoodMap) {
	for index := 0; index < TABLE_CAPACITY; index += 1 {
		map.entries[index].occupied = false
		map.entries[index].psl = 0
	}
	map.count = 0
}

map_max_psl :: proc "contextless" (map: ^RobinHoodMap) -> u32 {
	maximum := u32(0)
	for index := 0; index < TABLE_CAPACITY; index += 1 {
		if map.entries[index].occupied && map.entries[index].psl > maximum { maximum = map.entries[index].psl }
	}
	return maximum
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(8*byte)) }
}

@(export)
robin_hood_hash :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8,
		capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 0 || input[0] > MAX_OPERATIONS do return -1
	operation_count := int(input[0])
	if int(length) != 1 + 3*operation_count do return -1

	map := RobinHoodMap{}
	results: [MAX_OPERATIONS]i64 = {}
	for operation := 0; operation < operation_count; operation += 1 {
		offset := 1 + 3*operation
		opcode := input[offset]
		raw_key := input[offset+1]
		raw_value := input[offset+2]
		if opcode == 0 {
			if raw_key < 0 || raw_key > 4_294_967_295 || raw_value < 100 || raw_value > 1_000_000 do return -1
			if !map_put(&map, u32(raw_key), u32(raw_value)) || map.count > MAX_ACTIVE_ENTRIES do return -1
			results[operation] = -2
		} else if opcode == 1 || opcode == 2 {
			if raw_key < 0 || raw_key > 4_294_967_295 || raw_value != 0 do return -1
			key := u32(raw_key)
			if opcode == 1 { results[operation] = map_get(&map, key) }
			else if map_remove(&map, key) { results[operation] = 1 } else { results[operation] = 0 }
		} else if opcode >= 3 && opcode <= 7 {
			if raw_key != 0 || raw_value != 0 do return -1
			if opcode == 3 { results[operation] = i64(map.count) }
			else if opcode == 4 { results[operation] = i64((map.count * 100) / TABLE_CAPACITY) }
			else if opcode == 5 { results[operation] = i64(map_max_psl(&map)) }
			else if opcode == 6 { map_clear(&map); results[operation] = -3 }
			else if map.count == 0 { results[operation] = 1 } else { results[operation] = 0 }
		} else do return -1
	}

	output_bytes := operation_count * 8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8
	for operation := 0; operation < operation_count; operation += 1 {
		put_i64_le(&staged[0], operation*8, results[operation])
	}
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
