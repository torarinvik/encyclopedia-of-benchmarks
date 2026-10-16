@[export: 'modular_arithmetic']
pub fn modular_arithmetic(values &i64, length usize) i64 {
	if unsafe { values == nil } || length != 4 { return -1 }
	unsafe {
		op := values[0]; m := values[1]; a := values[2]; b := values[3]
		if op < 0 || op > 2 || m < 1 || m > 1_000_000 || a < 0 || a >= m || b < 0 || b >= m { return -1 }
		if op == 0 { return ((a % m) + (b % m)) % m }
		if op == 1 { return ((a % m) - (b % m) + m) % m }
		return ((a % m) * (b % m)) % m
	}
}
