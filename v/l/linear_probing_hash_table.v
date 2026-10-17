module linear_probing_hash_table

const max_table_capacity = 128
const max_operations = 32
const max_input_length = 66
const max_output_words = 1088
const max_key = i64(2147483520)

fn find_slot(table []i32, capacity int, key i32) int {
	mut index := int(key) % capacity
	for _ in 0 .. capacity {
		if table[index] == 0 { return -1 }
		if table[index] == key { return index }
		index = (index + 1) % capacity
	}
	return -1
}

fn insertion_slot(table []i32, capacity int, key i32) int {
	mut index := int(key) % capacity
	for _ in 0 .. capacity {
		if table[index] == 0 || table[index] == -1 { return index }
		index = (index + 1) % capacity
	}
	return -1
}

fn rehash(mut table []i32, mut capacity int) {
	old_capacity := capacity
	mut old_table := []i32{len: max_table_capacity}
	for i in 0 .. old_capacity { old_table[i] = table[i] }
	capacity *= 2
	for i in 0 .. capacity { table[i] = 0 }
	for i in 0 .. old_capacity {
		key := old_table[i]
		if key <= 0 { continue }
		slot := insertion_slot(table, capacity, key)
		if slot >= 0 { table[slot] = key }
	}
}

@[export: 'linear_probing_hash_table']
pub fn linear_probing_hash_table(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > 16 || input[1] < 0 || input[1] > max_operations { return -1 }
		mut table := []i32{len: max_table_capacity}
		mut table_capacity := int(input[0])
		operation_count := int(input[1])
		mut size := 0
		mut words := []i64{len: max_output_words}
		mut word_count := 0
		mut position := 2
		for _ in 0 .. operation_count {
			if position >= int(length) { return -1 }
			opcode := input[position]
			position++
			if opcode >= 0 && opcode <= 3 {
				if position >= int(length) { return -1 }
				key_arg := input[position]
				position++
				if key_arg < 1 || key_arg > max_key { return -1 }
				key := i32(key_arg)
				if opcode == 0 {
				slot := insertion_slot(table, table_capacity, key)
					if slot < 0 { return -1 }
					table[slot] = key
					size++
					words[word_count] = 0; words[word_count + 1] = 1; word_count += 2
					if size * 2 >= table_capacity { rehash(mut table, mut table_capacity) }
				} else if opcode == 1 {
					slot := find_slot(table, table_capacity, key)
					if slot < 0 { return -1 }
					table[slot] = -1
					size--
					words[word_count] = 1; words[word_count + 1] = 1; word_count += 2
				} else if opcode == 2 {
					words[word_count] = 2
					words[word_count + 1] = if find_slot(table, table_capacity, key) >= 0 { 1 } else { 0 }
					word_count += 2
				} else {
					words[word_count] = 3; words[word_count + 1] = key_arg; word_count += 2
				}
			} else if opcode == 4 {
				words[word_count] = 4; words[word_count + 1] = i64(table_capacity); word_count += 2
				for i in 0 .. table_capacity {
					words[word_count] = if table[i] == 0 { -2 } else { i64(table[i]) }
					word_count++
				}
			} else { return -1 }
		}
		if position != int(length) || word_count > max_output_words { return -1 }
		bytes := word_count * 8
		if output == nil || output_capacity < bytes { return -2 }
		for i in 0 .. word_count {
			bits := u64(words[i])
			for byte in 0 .. 8 { output[8 * i + byte] = u8((bits >> (8 * byte)) & u64(255)) }
		}
		return i64(bytes)
	}
}
