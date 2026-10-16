const max_ops = 256
const fnv_offset = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)

fn hash_i64(mut hash u64, value i64) u64 {
	bits := u64(value)
	for shift in 0 .. 8 { hash = (hash ^ u64(u8(bits >> (shift * 8)))) * fnv_prime }
	return hash
}

@[export: 'immutable_hash_map']
pub fn immutable_hash_map(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 1 + 3 * max_ops { return -1 }
	count64 := unsafe { input[0] }
	if count64 < 0 || count64 > max_ops || length != usize(1 + 3 * count64) { return -1 }
	count := int(count64)
	mut keys := [max_ops]i32{}
	mut values := [max_ops]i32{}
	mut trace := [max_ops]i64{}
	mut map_size := 0
	for i in 0 .. count {
		operation := unsafe { input[1 + 3 * i] }
		key64 := unsafe { input[2 + 3 * i] }
		value64 := unsafe { input[3 + 3 * i] }
		if operation < 0 || operation > 3 || key64 < i64(-2147483648) || key64 > i64(2147483647) || value64 < i64(-2147483648) || value64 > i64(2147483647) { return -1 }
		key := i32(key64)
		value := i32(value64)
		if operation == 0 {
			if value == 0 { return -1 }
			keys[map_size] = key
			values[map_size] = value
			map_size++
			trace[i] = i64(map_size)
		} else if operation == 1 || operation == 2 {
			mut found_value := i32(0)
			mut j := map_size
			for j > 0 {
				j--
				if keys[j] == key { found_value = values[j]; break }
			}
			if operation == 1 { trace[i] = i64(found_value) }
			else { trace[i] = if found_value != 0 { 1 } else { 0 } }
		} else {
			trace[i] = i64(map_size)
		}
	}
	mut hash := hash_i64(fnv_offset, count64)
	for i in 0 .. count { hash = hash_i64(hash, trace[i]) }
	return i64(hash & u64(0x7fffffffffffffff))
}
