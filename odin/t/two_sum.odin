package two_sum

import "core:c"

two_sum_hash_slot :: proc "contextless" (key: i64, capacity: uint) -> uint {
	prime: i64 = 2147483647
	normalized := key % prime
	if normalized < 0 {
		normalized += prime
	}
	mixed := (normalized * 48271) % prime
	return uint(mixed) % capacity
}

@(export)
two_sum :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length == 0 || length > 257 {
		return -2
	}
	for index := c.size_t(0); index < length; index += 1 {
		if values[index] < -2147483648 || values[index] > 2147483647 {
			return -2
		}
	}
	target := values[0]
	value_count := uint(length - 1)
	capacity := uint(1)
	for capacity < value_count*2 {
		capacity *= 2
	}
	keys: [512]i64
	first_indices: [512]uint
	occupied: [512]bool
	for index := 0; index < 512; index += 1 {
		occupied[index] = false
	}
	for index := uint(0); index < value_count; index += 1 {
		current := values[index+1]
		complement := target - current
		slot := two_sum_hash_slot(complement, capacity)
		for occupied[slot] && keys[slot] != complement {
			slot = (slot + 1) % capacity
		}
		if occupied[slot] {
			return i64(first_indices[slot]*256 + index)
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
