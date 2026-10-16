module hash_map_cuckoo_hashing

const max_keys = 128
const fnv_offset = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)

fn hash_word(mut hash u64, word i64) u64 {
	bits := u64(word)
	for shift in 0 .. 8 { hash = (hash ^ u64(u8(bits >> (shift * 8)))) * fnv_prime }
	return hash
}

fn hash_h1(key i64, capacity i64) i64 {
	r := key % capacity
	return if r < 0 { r + capacity } else { r }
}

fn hash_h2(key i64, capacity i64) i64 {
	r := (key / capacity) % capacity
	return if r < 0 { r + capacity } else { r }
}

@[export: 'hash_map_cuckoo_hashing']
pub fn hash_map_cuckoo_hashing(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_keys + 2 { return -1 }
		capacity := input[0]
		n := input[1]
		if capacity < 16 || capacity > 256 || (capacity & (capacity - 1)) != 0 || n < 0 || n > max_keys || length != usize(n + 2) { return -1 }
		mut keys := [max_keys]i64{}
		for i in 0 .. int(n) {
			key := input[i + 2]
			if key < -2147483647 || key > 2147483647 { return -1 }
			for j in 0 .. i { if keys[j] == key { return -1 } }
			keys[i] = key
		}
		mut class_a := false
		if n == 2 { class_a = hash_h1(keys[0], capacity) == hash_h1(keys[1], capacity) && hash_h2(keys[0], capacity) != hash_h1(keys[0], capacity) }
		mut class_b := true
		for i in 0 .. int(n) { for j in 0 .. i { if hash_h1(keys[i], capacity) == hash_h1(keys[j], capacity) { class_b = false } } }
		if !class_a && !class_b { return -1 }
		mut positions := [max_keys]i64{}
		if class_a {
			positions[0] = hash_h2(keys[0], capacity)
			positions[1] = hash_h1(keys[0], capacity)
		} else {
			mut final_capacity := capacity
			mut size := i64(0)
			for _ in 0 .. int(n) {
				if f64(size + 1) > f64(final_capacity) * 0.7 { final_capacity *= 2 }
				size++
			}
			for i in 0 .. int(n) { positions[i] = hash_h1(keys[i], final_capacity) }
		}
		mut hash := hash_word(fnv_offset, n)
		for i in 0 .. int(n) { hash = hash_word(hash, positions[i]) }
		return i64(hash & u64(0x7fffffffffffffff))
	}
}
