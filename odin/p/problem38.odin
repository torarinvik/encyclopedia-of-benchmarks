package problem38

is_9_pandigital :: proc(value: i64) -> bool {
	if value < 100000000 || value > 999999999 do return false
	mask := u32(0)
	remaining := value
	for remaining > 0 {
		digit := u32(remaining % 10)
		if digit == 0 || (mask & (1 << digit)) != 0 do return false
		mask |= 1 << digit
		remaining /= 10
	}
	return mask == 0x3fe
}

@(export)
problem38 :: proc "c" (unused: i64) -> i64 {
	if unused != 0 do return -1
	for base := i64(9999); base > 4999; base -= 1 {
		candidate := 100002 * base
		if is_9_pandigital(candidate) do return candidate
	}
	for base := i64(333); base > 99; base -= 1 {
		candidate := 1002003 * base
		if is_9_pandigital(candidate) do return candidate
	}
	return -1
}
