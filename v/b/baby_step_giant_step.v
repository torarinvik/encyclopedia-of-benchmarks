module baby_step_giant_step

const table_size = 65_536
const table_mask = table_size - 1
const max_modulus = u64(1_000_000_007)

fn gcd_u64(left u64, right u64) u64 {
	mut a := left
	mut b := right
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

fn ceil_sqrt(value u64) u64 {
	mut low := u64(1)
	mut high := u64(31_624)
	for low < high {
		middle := low + (high - low) / 2
		if middle * middle >= value { high = middle } else { low = middle + 1 }
	}
	return low
}

fn insert_baby(mut keys []u64, mut encoded_steps []u32, key u64, step u32) {
	mut slot := int(key & u64(table_mask))
	for encoded_steps[slot] != 0 && keys[slot] != key { slot = (slot + 1) & table_mask }
	keys[slot] = key
	encoded_steps[slot] = step + 1
}

fn find_baby(keys []u64, encoded_steps []u32, key u64) i64 {
	mut slot := int(key & u64(table_mask))
	for encoded_steps[slot] != 0 {
		if keys[slot] == key { return i64(encoded_steps[slot] - 1) }
		slot = (slot + 1) & table_mask
	}
	return -1
}

// Packed input [a, b, n]; return the least positive discrete logarithm or -1.
@[export: 'baby_step_giant_step']
pub fn baby_step_giant_step(values &i64, length usize) i64 {
	if values == nil || length != 3 { return -1 }
	unsafe {
		if values[0] < 0 || values[1] < 0 || values[2] < 1 || u64(values[2]) > max_modulus ||
				values[0] >= values[2] || values[1] >= values[2] { return -1 }
		a, b, modulus := u64(values[0]), u64(values[1]), u64(values[2])
		if gcd_u64(a, modulus) != 1 { return -1 }

		m := ceil_sqrt(modulus)
		mut keys := []u64{len: table_size}
		mut encoded_steps := []u32{len: table_size}
		mut step := u64(1)
		for index := u64(0); index < m; index++ {
			insert_baby(mut keys, mut encoded_steps, (step * b) % modulus, u32(index))
			step = (step * a) % modulus
		}
		giant_step := step
		mut index := m
		for index <= modulus {
			baby_index := find_baby(keys, encoded_steps, step)
			if baby_index >= 0 { return i64(index) - baby_index }
			step = (step * giant_step) % modulus
			index += m
		}
		return -1
	}
}
