package find_previous_power_of_two

// Repeated-doubling search from the pinned source, bounded to its i32 domain.
@(export)
find_previous_power_of_two :: proc "c" (number: i64) -> i64 {
	if number < 0 || number > 2_147_483_647 do return -1
	if number == 0 do return 0

	power: i64 = 1
	for power <= number {
		power <<= 1
	}
	if number > 1 do return power >> 1
	return 1
}
