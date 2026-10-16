package problem164

@(export)
problem164 :: proc "c" (n_digits: i64) -> i64 {
	if n_digits < 0 || n_digits > 26 do return -1
	if n_digits == 0 do return 1
	current: [100]i64
	next: [100]i64
	for first := 1; first <= 9; first += 1 { current[first * 10] = 1 }
	for used := i64(1); used < n_digits; used += 1 {
		for index := 0; index < 100; index += 1 { next[index] = 0 }
		for previous := 0; previous <= 9; previous += 1 {
			for before_previous := 0; before_previous <= 9; before_previous += 1 {
				ways := current[previous * 10 + before_previous]
				maximum_digit := 9 - previous - before_previous
				for digit := 0; digit <= maximum_digit; digit += 1 {
					next[digit * 10 + previous] += ways
				}
			}
		}
		for index := 0; index < 100; index += 1 { current[index] = next[index] }
	}
	total := i64(0)
	for index := 0; index < 100; index += 1 { total += current[index] }
	return total
}
