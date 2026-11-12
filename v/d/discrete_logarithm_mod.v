module discrete_logarithm_mod

const table_size = 65_536
const table_mask = table_size - 1
const max_modulus = u64(1_000_000_000)

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
	mut high := u64(31_623)
	for low < high {
		middle := low + (high - low) / 2
		if middle * middle >= value { high = middle } else { low = middle + 1 }
	}
	return low
}

fn pow_mod(base_value u64, exponent_value u64, modulus u64) u64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := u64(1) % modulus
	for exponent != 0 {
		if (exponent & 1) != 0 { result = (result * base) % modulus }
		base = (base * base) % modulus
		exponent >>= 1
	}
	return result
}

fn inverse_mod(value u64, modulus u64) i64 {
	mut old_r := i64(value)
	mut r := i64(modulus)
	mut old_t := i64(1)
	mut t := i64(0)
	for r != 0 {
		quotient := old_r / r
		next_r := old_r - quotient * r
		next_t := old_t - quotient * t
		old_r = r
		r = next_r
		old_t = t
		t = next_t
	}
	if old_r != 1 { return -1 }
	old_t %= i64(modulus)
	if old_t < 0 { old_t += i64(modulus) }
	return old_t
}

fn insert_baby(mut keys []u64, mut steps []u32, key u64, step u32) {
	mut slot := int(key & u64(table_mask))
	for steps[slot] != 0 {
		if keys[slot] == key { return }
		slot = (slot + 1) & table_mask
	}
	keys[slot] = key
	steps[slot] = step + 1
}

fn find_baby(keys []u64, steps []u32, key u64) i64 {
	mut slot := int(key & u64(table_mask))
	for steps[slot] != 0 {
		if keys[slot] == key { return i64(steps[slot] - 1) }
		slot = (slot + 1) & table_mask
	}
	return -1
}

fn coprime_log(x u64, y u64, modulus u64) i64 {
	if y == u64(1) % modulus { return 0 }
	width := ceil_sqrt(modulus)
	mut keys := []u64{len: table_size}
	mut steps := []u32{len: table_size}
	mut residue := u64(1) % modulus
	for step := u64(0); step < width; step++ {
		insert_baby(mut keys, mut steps, residue, u32(step))
		residue = (residue * x) % modulus
	}
	inverse := inverse_mod(x, modulus)
	if inverse < 0 { return -1 }
	giant_factor := pow_mod(u64(inverse), width, modulus)
	mut giant := y
	mut block := u64(0)
	for block * width <= modulus {
		baby := find_baby(keys, steps, giant)
		if baby >= 0 {
			answer := block * width + u64(baby)
			if answer <= modulus { return i64(answer) }
			return -1
		}
		giant = (giant * giant_factor) % modulus
		block++
	}
	return -1
}

fn extended_log(x u64, initial_y u64, initial_modulus u64) i64 {
	mut y := initial_y
	mut modulus := initial_modulus
	if modulus == 1 { return 0 }
	mut accumulator := u64(1)
	mut added := u64(0)
	for gcd_u64(x, modulus) > 1 {
		divisor := gcd_u64(x, modulus)
		if y == accumulator { return i64(added) }
		if y % divisor != 0 { return -1 }
		y /= divisor
		modulus /= divisor
		accumulator = (accumulator * (x / divisor)) % modulus
		added++
		if modulus == 1 { return i64(added) }
	}
	inverse := inverse_mod(accumulator, modulus)
	if inverse < 0 { return -1 }
	target := (y * u64(inverse)) % modulus
	remaining := coprime_log(x % modulus, target, modulus)
	if remaining < 0 { return -1 }
	return i64(added) + remaining
}

// Packed input [x, y, m]; return the least nonnegative exponent or -1.
@[export: 'discrete_logarithm_mod']
pub fn discrete_logarithm_mod(values &i64, length usize) i64 {
	if values == nil || length != 3 { return -1 }
	unsafe {
		if values[0] < 0 || values[1] < 0 || values[2] < 1 || u64(values[2]) > max_modulus ||
				values[0] >= values[2] || values[1] >= values[2] { return -1 }
		return extended_log(u64(values[0]), u64(values[1]), u64(values[2]))
	}
}
