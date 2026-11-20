module linear_hashing_trace

fn bucket_index(key i64, level int, split int) int {
	base := 1 << level
	mut remainder := key % i64(base)
	if remainder < 0 { remainder += i64(base) }
	mut index := int(remainder)
	if index < split {
		remainder = key % i64(base << 1)
		if remainder < 0 { remainder += i64(base << 1) }
		index = int(remainder)
	}
	return index
}

@[export: 'linear_hashing_trace']
pub fn linear_hashing_trace(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > 128 { return -1 }
		operation_count := values[0]
		if operation_count < 0 || operation_count > 63 || length != usize(1 + 2 * operation_count) { return -1 }

		mut heads := [32]int{}
		mut keys := [63]i64{}
		mut links := [63]int{}
		for bucket in 0 .. 32 { heads[bucket] = -1 }
		mut level := 1
		mut split := 0
		mut live_count := 0
		mut allocated := 0
		mut result := i64(0)

		for operation in 0 .. int(operation_count) {
			opcode := values[1 + 2 * operation]
			key := values[2 + 2 * operation]
			if opcode < 0 || opcode > 2 || key < -1024 || key > 1023 { return -1 }
			bucket := bucket_index(key, level, split)
			mut previous := -1
			mut node := heads[bucket]
			for node != -1 && keys[node] != key {
				previous = node
				node = links[node]
			}
			found := node != -1
			mut succeeded := i64(0)

			if opcode == 0 && !found {
				node = allocated
				allocated++
				keys[node] = key
				links[node] = heads[bucket]
				heads[bucket] = node
				live_count++
				succeeded = 1
				base := 1 << level
				bucket_count := base + split
				if bucket_count < 32 && live_count > 2 * bucket_count {
					old_bucket := split
					new_bucket := base + split
					mut current := heads[old_bucket]
					heads[old_bucket] = -1
					for current != -1 {
						following := links[current]
						mut remainder := keys[current] % i64(base << 1)
						if remainder < 0 { remainder += i64(base << 1) }
						if int(remainder) == new_bucket {
							links[current] = heads[new_bucket]
							heads[new_bucket] = current
						} else {
							links[current] = heads[old_bucket]
							heads[old_bucket] = current
						}
						current = following
					}
					split++
					if split == base {
						level++
						split = 0
					}
				}
			} else if opcode == 1 && found {
				if previous == -1 { heads[bucket] = links[node] }
				else { links[previous] = links[node] }
				live_count--
				succeeded = 1
			} else if opcode == 2 && found {
				succeeded = 1
			}
			result = (result << 1) | succeeded
		}
		return result
	}
}
