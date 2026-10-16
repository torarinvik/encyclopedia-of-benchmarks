module problem38

fn is_9_pandigital(value i64) bool {
	if value < 100000000 || value > 999999999 { return false }
	mut mask := u32(0)
	mut remaining := value
	for remaining > 0 {
		digit := u32(remaining % 10)
		if digit == 0 || (mask & (u32(1) << digit)) != 0 { return false }
		mask |= u32(1) << digit
		remaining /= 10
	}
	return mask == 0x3fe
}

@[export: 'problem38']
pub fn problem38(unused i64) i64 {
	if unused != 0 { return -1 }
	for mut base := i64(9999); base > 4999; base-- {
		candidate := 100002 * base
		if is_9_pandigital(candidate) { return candidate }
	}
	for mut base := i64(333); base > 99; base-- {
		candidate := 1002003 * base
		if is_9_pandigital(candidate) { return candidate }
	}
	return -1
}
