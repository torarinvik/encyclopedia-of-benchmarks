module linear_probing_hash_map

struct HashMap {
	mut:
		keys [128]i32
		values [128]i32
		occupied [128]bool
		capacity int
		size int
}

fn hash_index(key i32, capacity int) int {
	return int((u32(key) & u32(0x7fffffff)) % u32(capacity))
}

fn resize_map(mut map HashMap, new_capacity int) {
	old_keys := map.keys
	old_values := map.values
	old_occupied := map.occupied
	old_capacity := map.capacity
	map.capacity = new_capacity
	for i in 0 .. new_capacity { map.occupied[i] = false }
	for i in 0 .. old_capacity {
		if !old_occupied[i] { continue }
		mut index := hash_index(old_keys[i], new_capacity)
		for map.occupied[index] { index = (index + 1) % new_capacity }
		map.keys[index] = old_keys[i]
		map.values[index] = old_values[i]
		map.occupied[index] = true
	}
}

fn find_slot(map &HashMap, key i32) int {
	mut index := hash_index(key, map.capacity)
	for _ in 0 .. map.capacity {
		if !map.occupied[index] { return map.capacity }
		if map.keys[index] == key { return index }
		index = (index + 1) % map.capacity
	}
	return map.capacity
}

fn put(mut map HashMap, key i32, value i32) {
	if map.size > map.capacity / 2 { resize_map(mut map, map.capacity * 2) }
	mut index := hash_index(key, map.capacity)
	for map.occupied[index] {
		if map.keys[index] == key { map.values[index] = value; return }
		index = (index + 1) % map.capacity
	}
	map.keys[index] = key
	map.values[index] = value
	map.occupied[index] = true
	map.size++
}

fn delete_key(mut map HashMap, key i32) bool {
	mut index := find_slot(map, key)
	if index == map.capacity { return false }
	map.occupied[index] = false
	map.values[index] = 0
	index = (index + 1) % map.capacity
	for map.occupied[index] {
		k := map.keys[index]
		v := map.values[index]
		map.occupied[index] = false
		map.values[index] = 0
		map.size--
		put(mut map, k, v)
		index = (index + 1) % map.capacity
	}
	map.size--
	if map.size > 0 && map.size <= map.capacity / 8 { resize_map(mut map, map.capacity / 2) }
	return true
}

fn append_word(mut words [320]i64, mut count int, value i64) {
	words[count] = value
	count++
}

@[export: 'linear_probing_hash_map']
pub fn linear_probing_hash_map(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 98 { return -1 }
	if unsafe { input[0] < 4 || input[0] > 16 || input[1] < 0 || input[1] > 32 } { return -1 }
	op_count := int(unsafe { input[1] })
	if length > usize(2 + 3 * op_count) { return -1 }
	mut map := HashMap{capacity: int(unsafe { input[0] })}
	mut words := [320]i64{}
	mut word_count := 0
	mut pos := 2
	for _ in 0 .. op_count {
		if pos >= length { return -1 }
		op := unsafe { input[pos] }
		pos++
		if op == 0 {
			if pos + 1 >= length { return -1 }
			key := unsafe { input[pos] }; value := unsafe { input[pos + 1] }
			pos += 2
			if key < -2147483648 || key > 2147483647 || value < -2147483648 || value > 2147483647 { return -1 }
			put(mut map, i32(key), i32(value))
			append_word(mut words, mut word_count, 0); append_word(mut words, mut word_count, 1)
		} else if op >= 1 && op <= 3 {
			if pos >= length { return -1 }
			key := unsafe { input[pos] }; pos++
			if key < -2147483648 || key > 2147483647 { return -1 }
			k := i32(key)
			index := find_slot(map, k)
			if op == 1 {
				append_word(mut words, mut word_count, 1)
				if index == map.capacity { append_word(mut words, mut word_count, 1); append_word(mut words, mut word_count, 0) }
				else { append_word(mut words, mut word_count, 0); append_word(mut words, mut word_count, i64(map.values[index])) }
			} else if op == 2 {
				append_word(mut words, mut word_count, 2)
				append_word(mut words, mut word_count, if delete_key(mut map, k) { 1 } else { 0 })
			} else {
				append_word(mut words, mut word_count, 3)
				append_word(mut words, mut word_count, if index != map.capacity { 1 } else { 0 })
			}
		} else if op == 4 {
			append_word(mut words, mut word_count, 4); append_word(mut words, mut word_count, i64(map.size))
		} else if op == 5 {
			mut sorted := [32]i32{}
			mut count := 0
			for i in 0 .. map.capacity { if map.occupied[i] { sorted[count] = map.keys[i]; count++ } }
			for i in 1 .. count {
				value := sorted[i]; mut j := i
				for j > 0 && sorted[j - 1] > value { sorted[j] = sorted[j - 1]; j-- }
				sorted[j] = value
			}
			append_word(mut words, mut word_count, 5); append_word(mut words, mut word_count, i64(count))
			for i in 0 .. count { append_word(mut words, mut word_count, i64(sorted[i])) }
		} else { return -1 }
	}
	if pos != length || word_count > 320 { return -1 }
	bytes := word_count * 8
	if unsafe { output == nil } || output_capacity < bytes { return -2 }
	for i in 0 .. word_count {
		tag_bits := u64(words[i])
		for b in 0 .. 8 { unsafe { output[8 * i + b] = u8(tag_bits >> (8 * b)) } }
	}
	return i64(bytes)
}
