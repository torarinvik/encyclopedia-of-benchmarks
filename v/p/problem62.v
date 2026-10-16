module problem62

const table_size = 16_384
const max_base = 8_384
const signature_length_factor = i64(4_503_599_627_370_496)

fn digit_signature(cube i64) i64 {
	mut counts := [10]i64{}
	mut length := i64(0)
	mut remaining := cube
	for remaining > 0 {
		counts[int(remaining % 10)]++
		length++
		remaining /= 10
	}
	if length == 0 {
		counts[0] = 1
		length = 1
	}
	mut sorted_digits := i64(0)
	for digit in 0 .. 10 {
		mut occurrence := i64(0)
		for occurrence < counts[digit] {
			sorted_digits = sorted_digits * 16 + i64(digit)
			occurrence++
		}
	}
	return length * signature_length_factor + sorted_digits
}

fn signature_slot(key i64) int {
	size := i64(table_size)
	hash := (key % size + (key / size % size) * 31 +
		(key / (size * size) % size) * 17 +
		(key / (size * size * size) % size) * 7) % size
	return int(hash)
}

@[export: 'problem62']
pub fn problem62(target_count i64) i64 {
	if target_count < 1 || target_count > 5 {
		return -1
	}
	mut keys := [table_size]i64{}
	mut first_cubes := [table_size]i64{}
	mut counts := [table_size]int{}
	for base in 0 .. max_base + 1 {
		base_i64 := i64(base)
		cube := base_i64 * base_i64 * base_i64
		key := digit_signature(cube)
		mut slot := signature_slot(key)
		for keys[slot] != 0 && keys[slot] != key {
			slot = (slot + 1) % table_size
		}
		if keys[slot] == 0 {
			keys[slot] = key
			first_cubes[slot] = cube
		}
		counts[slot]++
		if i64(counts[slot]) == target_count {
			return first_cubes[slot]
		}
	}
	return -1
}
