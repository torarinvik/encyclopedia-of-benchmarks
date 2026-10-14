package power_of_four

// Positive powers of four within the signed 32-bit source domain.
@(export)
power_of_four :: proc "c" (value: i64) -> i64 {
	if value < -2_147_483_648 || value > 2_147_483_647 do return -1
	if value <= 0 || (value & (value - 1)) != 0 do return 0
	if (value & 0x5555_5555) != 0 do return 1
	return 0
}
