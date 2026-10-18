const max_operations = 24
const max_initial_capacity = 8
const max_table_capacity = 64
const max_input_length = 51
const max_output_bytes = 600

struct QphTable {
	slots [max_table_capacity]i64
	mut:
	capacity int
	size int
}

fn qph_probe_insert(table &QphTable, key i64) int {
	for probe in 0 .. table.capacity * 100 {
		index := (int(key) + probe * probe) % table.capacity
		if table.slots[index] == 0 || table.slots[index] == -1 { return index }
	}
	return -1
}

fn qph_probe_find(table &QphTable, key i64) int {
	for probe in 0 .. table.capacity * 100 {
		index := (int(key) + probe * probe) % table.capacity
		slot := table.slots[index]
		if slot == 0 { return -1 }
		if slot == key { return index }
	}
	return -1
}

fn qph_insert_key(mut table QphTable, key i64) bool

fn qph_rehash(mut table QphTable) bool {
	old_capacity := table.capacity
	if old_capacity > max_table_capacity / 2 { return false }
	old_slots := table.slots
	table.capacity = old_capacity * 2
	for index in 0 .. table.capacity { table.slots[index] = 0 }
	for index in 0 .. old_capacity {
		key := old_slots[index]
		if key == 0 || key == -1 { continue }
		if table.size == 0 { return false }
		table.size--
		if !qph_insert_key(mut table, key) { return false }
	}
	return true
}

fn qph_insert_key(mut table QphTable, key i64) bool {
	index := qph_probe_insert(table, key)
	if index < 0 { return false }
	table.slots[index] = key
	table.size++
	if table.size * 2 >= table.capacity { return qph_rehash(mut table) }
	return true
}

fn qph_put_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'quadratic_probing_hash_table']
pub fn quadratic_probing_hash_table(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > max_input_length { return -1 }
		if input[0] < 1 || input[0] > max_initial_capacity || input[1] < 0 || input[1] > max_operations { return -1 }
		operation_count := int(input[1])
		if input_length != usize(2 + 2 * operation_count) { return -1 }

		mut table := QphTable{capacity: int(input[0])}
		mut active := [65]bool{}
		mut find_results := [24]i64{}
		mut find_count := 0
		for operation_index in 0 .. operation_count {
			operation := input[2 + 2 * operation_index]
			key := input[3 + 2 * operation_index]
			if operation < 0 || operation > 2 || key < 1 || key > 64 { return -1 }
			key_index := int(key)
			if operation == 0 {
				if active[key_index] || !qph_insert_key(mut table, key) { return -1 }
				active[key_index] = true
			} else if operation == 1 {
				if !active[key_index] { return -1 }
				index := qph_probe_find(table, key)
				if index < 0 { return -1 }
				table.slots[index] = -1
				active[key_index] = false
				table.size--
			} else {
				index := qph_probe_find(table, key)
				find_results[find_count] = if index <= 0 { i64(0) } else { table.slots[index] }
				find_count++
			}
		}

		output_words := 3 + find_count + table.capacity
		output_bytes := output_words * 8
		if output_bytes > max_output_bytes { return -1 }
		if output == nil || capacity < usize(output_bytes) { return -2 }
		qph_put_i64_le(mut output, 0, i64(table.capacity))
		qph_put_i64_le(mut output, 8, i64(table.size))
		qph_put_i64_le(mut output, 16, i64(find_count))
		for index in 0 .. find_count { qph_put_i64_le(mut output, (3 + index) * 8, find_results[index]) }
		for index in 0 .. table.capacity { qph_put_i64_le(mut output, (3 + find_count + index) * 8, table.slots[index]) }
		return i64(output_bytes)
	}
}
