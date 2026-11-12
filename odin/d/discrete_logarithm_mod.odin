package discrete_logarithm_mod

import "core:c"

TABLE_SIZE :: 65_536
TABLE_MASK :: TABLE_SIZE - 1
MAX_MODULUS :: u64(1_000_000_000)

gcd_u64 :: proc "contextless" (left, right: u64) -> u64 {
	a, b := left, right
	for b != 0 {
		remainder := a % b
		a, b = b, remainder
	}
	return a
}

ceil_sqrt :: proc "contextless" (value: u64) -> u64 {
	low, high := u64(1), u64(31_623)
	for low < high {
		middle := low + (high - low) / 2
		if middle * middle >= value { high = middle } else { low = middle + 1 }
	}
	return low
}

pow_mod :: proc "contextless" (base_value, exponent_value, modulus: u64) -> u64 {
	base, exponent := base_value, exponent_value
	result := u64(1) % modulus
	for exponent != 0 {
		if (exponent & 1) != 0 { result = (result * base) % modulus }
		base = (base * base) % modulus
		exponent >>= 1
	}
	return result
}

inverse_mod :: proc "contextless" (value, modulus: u64) -> i64 {
	old_r, r := i64(value), i64(modulus)
	old_t, t := i64(1), i64(0)
	for r != 0 {
		quotient := old_r / r
		next_r := old_r - quotient * r
		next_t := old_t - quotient * t
		old_r, r = r, next_r
		old_t, t = t, next_t
	}
	if old_r != 1 do return -1
	old_t %= i64(modulus)
	if old_t < 0 { old_t += i64(modulus) }
	return old_t
}

insert_baby :: proc "contextless" (keys: []u64, steps: []u32, key: u64, step: u32) {
	slot := int(key & u64(TABLE_MASK))
	for steps[slot] != 0 {
		if keys[slot] == key do return
		slot = (slot + 1) & TABLE_MASK
	}
	keys[slot] = key
	steps[slot] = step + 1
}

find_baby :: proc "contextless" (keys: []u64, steps: []u32, key: u64) -> i64 {
	slot := int(key & u64(TABLE_MASK))
	for steps[slot] != 0 {
		if keys[slot] == key do return i64(steps[slot] - 1)
		slot = (slot + 1) & TABLE_MASK
	}
	return -1
}

coprime_log :: proc "contextless" (x, y, modulus: u64) -> i64 {
	if y == 1 % modulus do return 0
	width := ceil_sqrt(modulus)
	keys := make([]u64, TABLE_SIZE)
	defer delete(keys)
	steps := make([]u32, TABLE_SIZE)
	defer delete(steps)
	residue := u64(1) % modulus
	for step := u64(0); step < width; step += 1 {
		insert_baby(keys, steps, residue, u32(step))
		residue = (residue * x) % modulus
	}
	inverse := inverse_mod(x, modulus)
	if inverse < 0 do return -1
	giant_factor := pow_mod(u64(inverse), width, modulus)
	giant := y
	for block := u64(0); block * width <= modulus; block += 1 {
		baby := find_baby(keys, steps, giant)
		if baby >= 0 {
			answer := block * width + u64(baby)
			if answer <= modulus do return i64(answer)
			return -1
		}
		giant = (giant * giant_factor) % modulus
	}
	return -1
}

extended_log :: proc "contextless" (x, initial_y, initial_modulus: u64) -> i64 {
	y, modulus := initial_y, initial_modulus
	if modulus == 1 do return 0
	accumulator, added := u64(1), u64(0)
	for gcd_u64(x, modulus) > 1 {
		divisor := gcd_u64(x, modulus)
		if y == accumulator do return i64(added)
		if y % divisor != 0 do return -1
		y /= divisor
		modulus /= divisor
		accumulator = (accumulator * (x / divisor)) % modulus
		added += 1
		if modulus == 1 do return i64(added)
	}
	inverse := inverse_mod(accumulator, modulus)
	if inverse < 0 do return -1
	target := (y * u64(inverse)) % modulus
	remaining := coprime_log(x % modulus, target, modulus)
	if remaining < 0 do return -1
	return i64(added) + remaining
}

// Packed input [x, y, m]; return the least nonnegative exponent or -1.
@(export)
discrete_logarithm_mod :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 3 do return -1
	if values[0] < 0 || values[1] < 0 || values[2] < 1 || u64(values[2]) > MAX_MODULUS ||
		values[0] >= values[2] || values[1] >= values[2] do return -1
	return extended_log(u64(values[0]), u64(values[1]), u64(values[2]))
}
