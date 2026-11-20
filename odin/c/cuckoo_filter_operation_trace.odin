package cuckoo_filter_operation_trace

import "core:c"

BUCKETS :: 8
WIDTH :: 4
MAX_OPERATIONS :: 32
MAX_KICKS :: 8

delta :: proc(fingerprint: i64) -> int {
	return 1 + (5 * int(fingerprint) + 3) % 7
}

first_empty :: proc(table: [^]i64, bucket: int) -> int {
	for slot := 0; slot < WIDTH; slot += 1 {
		if table[bucket * WIDTH + slot] == 0 do return slot
	}
	return WIDTH
}

insert :: proc(table: [^]i64, primary: int, fingerprint: i64) -> bool {
	alternate := primary ^ delta(fingerprint)
	empty := first_empty(table, primary)
	if empty < WIDTH { table[primary * WIDTH + empty] = fingerprint; return true }
	empty = first_empty(table, alternate)
	if empty < WIDTH { table[alternate * WIDTH + empty] = fingerprint; return true }
	current := primary
	pending := fingerprint
	for kick := 0; kick < MAX_KICKS; kick += 1 {
		position := current * WIDTH
		evicted := table[position]
		table[position] = pending
		pending = evicted
		current ^= delta(pending)
		empty = first_empty(table, current)
		if empty < WIDTH { table[current * WIDTH + empty] = pending; return true }
	}
	return false
}

write_i64_le :: proc(output: [^]u8, index: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[index * 8 + byte] = u8(bits >> u64(8 * byte)) }
}

@(export)
cuckoo_filter_operation_trace :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 98 do return -1
	raw_count := input[0]
	if raw_count < 1 || raw_count > MAX_OPERATIONS do return -1
	count := int(raw_count)
	if length != c.size_t(1 + 3 * count) do return -1
	for operation := 0; operation < count; operation += 1 {
		opcode := input[1 + 3 * operation]
		primary := input[2 + 3 * operation]
		fingerprint := input[3 + 3 * operation]
		if opcode < 0 || opcode > 2 || primary < 0 || primary >= BUCKETS || fingerprint < 1 || fingerprint > 15 do return -1
	}
	required := count * 8
	if output == nil || capacity < c.size_t(required) do return -2

	table: [BUCKETS * WIDTH]i64
	for i := 0; i < BUCKETS * WIDTH; i += 1 { table[i] = 0 }
	statuses: [MAX_OPERATIONS]i64
	for operation := 0; operation < count; operation += 1 {
		opcode := input[1 + 3 * operation]
		primary := int(input[2 + 3 * operation])
		fingerprint := input[3 + 3 * operation]
		alternate := primary ^ delta(fingerprint)
		if opcode == 0 {
			if !insert(&table[0], primary, fingerprint) do return -3
			statuses[operation] = 1
		} else if opcode == 1 {
			found := false
			for order := 0; order < 2; order += 1 {
				bucket := primary
				if order == 1 { bucket = alternate }
				for slot := 0; slot < WIDTH; slot += 1 { if table[bucket * WIDTH + slot] == fingerprint { found = true } }
			}
			if found { statuses[operation] = 1 } else { statuses[operation] = 0 }
		} else {
			removed := false
			for order := 0; order < 2 && !removed; order += 1 {
				bucket := primary
				if order == 1 { bucket = alternate }
				for slot := 0; slot < WIDTH; slot += 1 {
					position := bucket * WIDTH + slot
					if table[position] == fingerprint { table[position] = 0; removed = true; break }
				}
			}
			if removed { statuses[operation] = 1 } else { statuses[operation] = 0 }
		}
	}
	for operation := 0; operation < count; operation += 1 { write_i64_le(output, operation, statuses[operation]) }
	return i64(required)
}
