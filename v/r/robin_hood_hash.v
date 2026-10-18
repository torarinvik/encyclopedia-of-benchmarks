module robin_hood_hash

const table_capacity = 16
const max_active_entries = 14
const max_operations = 64
const max_input_length = 1 + 3 * max_operations
const max_output_bytes = 8 * max_operations
const max_probe_distance = u32(64)
const golden_ratio = u64(0x9e3779b97f4a7c15)

struct Entry {
	key u32
	value u32
	psl u32
	occupied bool
}

struct RobinHoodMap {
mut:
	entries [table_capacity]Entry
	count int
}

fn hash_key(key u32) int {
	product := u64(key) *% golden_ratio
	return int((product >> 32) & u64(table_capacity - 1))
}

fn (mut map RobinHoodMap) put(key u32, value u32) bool {
	if (map.count * 100) / table_capacity >= 90 { return false }
	mut entry := Entry{key: key, value: value, psl: 0, occupied: true}
	mut index := hash_key(key)
	mut probes := u32(0)
	for probes < max_probe_distance {
		if !map.entries[index].occupied {
			map.entries[index] = entry
			map.count++
			return true
		}
		if map.entries[index].key == key {
			map.entries[index].value = value
			return true
		}
		if entry.psl > map.entries[index].psl {
			tmp := map.entries[index]
			map.entries[index] = entry
			entry = tmp
		}
		entry.psl++
		index = (index + 1) & (table_capacity - 1)
		probes++
	}
	return false
}

fn (map RobinHoodMap) get(key u32) i64 {
	mut index := hash_key(key)
	mut psl := u32(0)
	for psl < max_probe_distance {
		resident := map.entries[index]
		if !resident.occupied { return -1 }
		if resident.key == key { return i64(resident.value) }
		if psl > resident.psl { return -1 }
		index = (index + 1) & (table_capacity - 1)
		psl++
	}
	return -1
}

fn (mut map RobinHoodMap) backshift(start int) {
	mut index := start
	for _ in 0 .. table_capacity {
		next := (index + 1) & (table_capacity - 1)
		if !map.entries[next].occupied || map.entries[next].psl == 0 {
			map.entries[index].occupied = false
			map.entries[index].psl = 0
			return
		}
		map.entries[index] = map.entries[next]
		map.entries[index].psl--
		index = next
	}
}

fn (mut map RobinHoodMap) remove(key u32) bool {
	mut index := hash_key(key)
	mut psl := u32(0)
	for psl < max_probe_distance {
		resident := map.entries[index]
		if !resident.occupied { return false }
		if resident.key == key {
			map.backshift(index)
			map.count--
			return true
		}
		if psl > resident.psl { return false }
		index = (index + 1) & (table_capacity - 1)
		psl++
	}
	return false
}

fn (mut map RobinHoodMap) clear() {
	for index in 0 .. table_capacity {
		map.entries[index].occupied = false
		map.entries[index].psl = 0
	}
	map.count = 0
}

fn (map RobinHoodMap) max_psl() u32 {
	mut maximum := u32(0)
	for entry in map.entries {
		if entry.occupied && entry.psl > maximum { maximum = entry.psl }
	}
	return maximum
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'robin_hood_hash']
pub fn robin_hood_hash(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_length { return -1 }
		if input[0] < 0 || input[0] > max_operations { return -1 }
		operation_count := int(input[0])
		if int(length) != 1 + 3 * operation_count { return -1 }

		mut map := RobinHoodMap{}
		mut results := [max_operations]i64{}
		for operation in 0 .. operation_count {
			offset := 1 + 3 * operation
			opcode := input[offset]
			raw_key := input[offset + 1]
			raw_value := input[offset + 2]
			if opcode == 0 {
				if raw_key < 0 || raw_key > 4_294_967_295 || raw_value < 100 || raw_value > 1_000_000 { return -1 }
				if !map.put(u32(raw_key), u32(raw_value)) || map.count > max_active_entries { return -1 }
				results[operation] = -2
			} else if opcode == 1 || opcode == 2 {
				if raw_key < 0 || raw_key > 4_294_967_295 || raw_value != 0 { return -1 }
				key := u32(raw_key)
				if opcode == 1 { results[operation] = map.get(key) }
				else if map.remove(key) { results[operation] = 1 }
				else { results[operation] = 0 }
			} else if opcode >= 3 && opcode <= 7 {
				if raw_key != 0 || raw_value != 0 { return -1 }
				if opcode == 3 { results[operation] = i64(map.count) }
				else if opcode == 4 { results[operation] = i64((map.count * 100) / table_capacity) }
				else if opcode == 5 { results[operation] = i64(map.max_psl()) }
				else if opcode == 6 { map.clear(); results[operation] = -3 }
				else if map.count == 0 { results[operation] = 1 }
				else { results[operation] = 0 }
			} else { return -1 }
		}

		output_bytes := operation_count * 8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{}
		for operation in 0 .. operation_count { put_i64_le(mut staged[0], operation * 8, results[operation]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
