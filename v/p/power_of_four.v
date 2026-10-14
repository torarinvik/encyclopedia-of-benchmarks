module power_of_four

// Positive powers of four within the signed 32-bit source domain.
@[export: 'power_of_four']
pub fn power_of_four(value i64) i64 {
	if value < -2147483648 || value > 2147483647 { return -1 }
	if value <= 0 || (value & (value - 1)) != 0 { return 0 }
	if (value & 1431655765) != 0 { return 1 }
	return 0
}
