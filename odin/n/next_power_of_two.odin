package next_power_of_two

// Bit spreading for the pinned positive 32-bit source domain.
@(export)
next_power_of_two :: proc "c" (number: i64) -> i64 {
	if number < 1 || number > 1_073_741_824 do return -1
	if (number & (number - 1)) == 0 do return number

	value := number - 1
	value |= value >> 1
	value |= value >> 2
	value |= value >> 4
	value |= value >> 8
	value |= value >> 16
	return value + 1
}
