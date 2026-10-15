package hardy_ramanujanalgo

@(export)
hardy_ramanujanalgo :: proc "c" (value: i64) -> i64 {
	if value < 1 || value > 2_147_483_647 do return -1

	remaining := value
	count: i64 = 0
	if remaining % 2 == 0 do count += 1
	for remaining % 2 == 0 {
		remaining /= 2
	}

	for factor: i64 = 3; factor <= remaining / factor; factor += 2 {
		if remaining % factor == 0 {
			count += 1
			for remaining % factor == 0 {
				remaining /= factor
			}
		}
	}
	if remaining > 2 do count += 1
	return count
}
