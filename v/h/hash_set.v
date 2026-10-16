module hash_set

const max_ids = 64
const max_input_length = 130
const capacity = 1024
const fnv_offset_basis = u64(0xcbf29ce484222325)
const fnv_prime = u64(0x100000001b3)

fn adler_key(id i64) u64 {
	mut a := u64(1)
	mut b := u64(0)
	for byte in [u64(107), u64(101), u64(121)] {
		a = (a + byte) % u64(65521)
		b = (b + a) % u64(65521)
	}
	if id >= 10 {
		a = (a + u64(id / 10 + 48)) % u64(65521)
		b = (b + a) % u64(65521)
	}
	a = (a + u64(id % 10 + 48)) % u64(65521)
	b = (b + a) % u64(65521)
	return (b << 16) | a
}

fn bucket_for_id(id i64) int {
	hash := adler_key(id)
	return int((u64(capacity - 1)) & (hash ^ (hash >> 12)))
}

fn fnv_word(hash u64, value i64) u64 {
	bits := u64(value)
	mut result := hash
	for byte in 0 .. 8 {
		result = (result ^ ((bits >> (8 * byte)) & u64(255))) * fnv_prime
	}
	return result
}

@[export: 'hash_set']
pub fn hash_set(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > i64(max_ids) { return -1 }
		add_count := int(input[0])
		query_count_index := 1 + add_count
		if usize(query_count_index) >= length || input[query_count_index] < 0 || input[query_count_index] > i64(max_ids) { return -1 }
		query_count := int(input[query_count_index])
		if length != usize(2 + add_count + query_count) { return -1 }

		for index in 0 .. add_count {
			if input[1 + index] < 0 || input[1 + index] >= i64(max_ids) { return -1 }
		}
		for index in 0 .. query_count {
			if input[query_count_index + 1 + index] < 0 || input[query_count_index + 1 + index] >= i64(max_ids) { return -1 }
		}

		mut occupied := [capacity]bool{}
		mut slot_ids := [capacity]i64{}
		mut set_length := i64(0)
		for index in 0 .. add_count {
			id := input[1 + index]
			bucket := bucket_for_id(id)
			if !occupied[bucket] {
				occupied[bucket] = true
				slot_ids[bucket] = id
				set_length++
			} else if slot_ids[bucket] != id {
				return -1
			}
		}

		mut result := fnv_word(fnv_offset_basis, set_length)
		for index in 0 .. query_count {
			id := input[query_count_index + 1 + index]
			bucket := bucket_for_id(id)
			contains := i64(0)
			if occupied[bucket] && slot_ids[bucket] == id { contains = 1 }
			result = fnv_word(result, contains)
		}
		return i64(result & 0x7fffffffffffffff)
	}
}
