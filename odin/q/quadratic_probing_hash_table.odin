package quadratic_probing_hash_table

import "core:c"

MAX_OPERATIONS :: 24
MAX_INITIAL_CAPACITY :: 8
MAX_TABLE_CAPACITY :: 64
MAX_INPUT_LENGTH :: 51
MAX_OUTPUT_BYTES :: 600

Table :: struct {
	slots: [MAX_TABLE_CAPACITY]i64,
	capacity: int,
	size: int,
}

probe_insert :: proc(table: ^Table, key: i64) -> int {
	for probe := 0; probe < table.capacity * 100; probe += 1 {
		index := (int(key) + probe * probe) % table.capacity
		if table.slots[index] == 0 || table.slots[index] == -1 do return index
	}
	return -1
}

probe_find :: proc(table: ^Table, key: i64) -> int {
	for probe := 0; probe < table.capacity * 100; probe += 1 {
		index := (int(key) + probe * probe) % table.capacity
		slot := table.slots[index]
		if slot == 0 do return -1
		if slot == key do return index
	}
	return -1
}

insert_key :: proc(table: ^Table, key: i64) -> bool

rehash :: proc(table: ^Table) -> bool {
	old_capacity := table.capacity
	if old_capacity > MAX_TABLE_CAPACITY / 2 do return false
	old_slots := table.slots
	table.capacity = old_capacity * 2
	for index := 0; index < table.capacity; index += 1 do table.slots[index] = 0
	for index := 0; index < old_capacity; index += 1 {
		key := old_slots[index]
		if key == 0 || key == -1 do continue
		if table.size == 0 do return false
		table.size -= 1
		if !insert_key(table, key) do return false
	}
	return true
}

insert_key :: proc(table: ^Table, key: i64) -> bool {
	index := probe_insert(table, key)
	if index < 0 do return false
	table.slots[index] = key
	table.size += 1
	if table.size * 2 >= table.capacity do return rehash(table)
	return true
}

put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(8 * byte)) & 255)
	}
}

@(export)
quadratic_probing_hash_table :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > MAX_INPUT_LENGTH do return -1
	if input[0] < 1 || input[0] > MAX_INITIAL_CAPACITY || input[1] < 0 || input[1] > MAX_OPERATIONS do return -1
	operation_count := int(input[1])
	if input_length != c.size_t(2 + 2 * operation_count) do return -1

	table := Table{capacity = int(input[0])}
	active: [MAX_TABLE_CAPACITY + 1]bool
	find_results: [MAX_OPERATIONS]i64
	find_count := 0
	for operation_index := 0; operation_index < operation_count; operation_index += 1 {
		operation := input[2 + 2 * operation_index]
		key := input[3 + 2 * operation_index]
		if operation < 0 || operation > 2 || key < 1 || key > 64 do return -1
		key_index := int(key)
		if operation == 0 {
			if active[key_index] || !insert_key(&table, key) do return -1
			active[key_index] = true
		} else if operation == 1 {
			if !active[key_index] do return -1
			index := probe_find(&table, key)
			if index < 0 do return -1
			table.slots[index] = -1
			active[key_index] = false
			table.size -= 1
		} else {
			index := probe_find(&table, key)
			find_results[find_count] = if index <= 0 do 0 else table.slots[index]
			find_count += 1
		}
	}

	output_words := 3 + find_count + table.capacity
	output_bytes := output_words * 8
	if output_bytes > MAX_OUTPUT_BYTES do return -1
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	put_i64_le(output, 0, i64(table.capacity))
	put_i64_le(output, 8, i64(table.size))
	put_i64_le(output, 16, i64(find_count))
	for index := 0; index < find_count; index += 1 {
		put_i64_le(output, (3 + index) * 8, find_results[index])
	}
	for index := 0; index < table.capacity; index += 1 {
		put_i64_le(output, (3 + find_count + index) * 8, table.slots[index])
	}
	return i64(output_bytes)
}
