package baby_step_giant_step

import "core:c"

TABLE_SIZE :: 65_536
TABLE_MASK :: TABLE_SIZE - 1
MAX_MODULUS :: u64(1_000_000_007)

gcd_u64 :: proc "contextless" (left, right: u64) -> u64 {
	a, b := left, right
	for b != 0 {
		remainder := a % b
		a, b = b, remainder
	}
	return a
}

ceil_sqrt :: proc "contextless" (value: u64) -> u64 {
	low, high := u64(1), u64(31_624)
	for low < high {
		middle := low + (high - low) / 2
		if middle * middle >= value { high = middle } else { low = middle + 1 }
	}
	return low
}

insert_baby :: proc "contextless" (keys: []u64, encoded_steps: []u32, key: u64, step: u32) {
	slot := int(key & u64(TABLE_MASK))
	for encoded_steps[slot] != 0 && keys[slot] != key { slot = (slot + 1) & TABLE_MASK }
	keys[slot] = key
	encoded_steps[slot] = step + 1
}

find_baby :: proc "contextless" (keys: []u64, encoded_steps: []u32, key: u64) -> i64 {
	slot := int(key & u64(TABLE_MASK))
	for encoded_steps[slot] != 0 {
		if keys[slot] == key do return i64(encoded_steps[slot] - 1)
		slot = (slot + 1) & TABLE_MASK
	}
	return -1
}

// Packed input [a, b, n]; return the least positive discrete logarithm or -1.
@(export)
baby_step_giant_step :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 3 do return -1
	if values[0] < 0 || values[1] < 0 || values[2] < 1 ||
			u64(values[2]) > MAX_MODULUS || values[0] >= values[2] || values[1] >= values[2] do return -1
	a, b, modulus := u64(values[0]), u64(values[1]), u64(values[2])
	if gcd_u64(a, modulus) != 1 do return -1

	m := ceil_sqrt(modulus)
	keys := make([]u64, TABLE_SIZE)
	defer delete(keys)
	encoded_steps := make([]u32, TABLE_SIZE)
	defer delete(encoded_steps)
	step := u64(1)
	for index := u64(0); index < m; index += 1 {
		insert_baby(keys, encoded_steps, (step * b) % modulus, u32(index))
		step = (step * a) % modulus
	}
	giant_step := step
	for index := m; index <= modulus; index += m {
		baby_index := find_baby(keys, encoded_steps, step)
		if baby_index >= 0 do return i64(index) - baby_index
		step = (step * giant_step) % modulus
	}
	return -1
}
