module two_sum

fn two_sum_hash_slot(key i64, capacity usize) usize {
	mut normalized := key % i64(2147483647)
	if normalized < 0 {
		normalized += i64(2147483647)
	}
	mixed := (normalized * i64(48271)) % i64(2147483647)
	return usize(mixed) % capacity
}

// Return the first matching pair as left_index * 256 + right_index.
@[export: 'two_sum']
pub fn two_sum(values &i64, length usize) i64 {
	if length == 0 || length > 257 {
		return -2
	}
	unsafe {
		for index in 0 .. length {
			if values[index] < i64(-2147483647) - 1 || values[index] > i64(2147483647) {
				return -2
			}
		}
		target := values[0]
		value_count := length - 1
		mut capacity := usize(1)
		for capacity < value_count * 2 {
			capacity *= 2
		}
		mut keys := [512]i64{init: 0}
		mut first_indices := [512]usize{init: 0}
		mut occupied := [512]bool{init: false}
		for index in 0 .. value_count {
			current := values[index + 1]
			complement := target - current
			mut slot := two_sum_hash_slot(complement, capacity)
			for occupied[slot] && keys[slot] != complement {
				slot = (slot + 1) % capacity
			}
			if occupied[slot] {
				return i64(first_indices[slot] * 256 + index)
			}
			slot = two_sum_hash_slot(current, capacity)
			for occupied[slot] && keys[slot] != current {
				slot = (slot + 1) % capacity
			}
			if !occupied[slot] {
				occupied[slot] = true
				keys[slot] = current
				first_indices[slot] = index
			}
		}
		return -1
	}
}
