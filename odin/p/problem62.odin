package problem62

TABLE_SIZE :: 16_384
MAX_BASE :: 8_384
SIGNATURE_LENGTH_FACTOR :: i64(4_503_599_627_370_496)

digit_signature :: proc(cube: i64) -> i64 {
	counts: [10]i64 = {}
	length := 0
	remaining := cube
	for remaining > 0 {
		counts[int(remaining % 10)] += 1
		length += 1
		remaining /= 10
	}
	if length == 0 {
		counts[0] = 1
		length = 1
	}
	sorted_digits: i64 = 0
	for digit := 0; digit < 10; digit += 1 {
		for occurrence := i64(0); occurrence < counts[digit]; occurrence += 1 {
			sorted_digits = sorted_digits * 16 + i64(digit)
		}
	}
	return i64(length) * SIGNATURE_LENGTH_FACTOR + sorted_digits
}

signature_slot :: proc(key: i64) -> int {
	size := i64(TABLE_SIZE)
	hash := (key % size + (key / size % size) * 31 +
	         (key / (size * size) % size) * 17 +
	         (key / (size * size * size) % size) * 7) % size
	return int(hash)
}

@(export)
problem62 :: proc "c" (target_count: i64) -> i64 {
	if target_count < 1 || target_count > 5 { return -1 }
	keys: [TABLE_SIZE]i64 = {}
	first_cubes: [TABLE_SIZE]i64 = {}
	counts: [TABLE_SIZE]int = {}
	for base := 0; base <= MAX_BASE; base += 1 {
		base_i64 := i64(base)
		cube := base_i64 * base_i64 * base_i64
		key := digit_signature(cube)
		slot := signature_slot(key)
		for keys[slot] != 0 && keys[slot] != key {
			slot = (slot + 1) % TABLE_SIZE
		}
		if keys[slot] == 0 {
			keys[slot] = key
			first_cubes[slot] = cube
		}
		counts[slot] += 1
		if i64(counts[slot]) == target_count { return first_cubes[slot] }
	}
	return -1
}
