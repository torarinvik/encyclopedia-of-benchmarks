package problem51

PRIME_LIMIT :: 1_000_000
PRIME :: u8(1)
FILTERED_PRIME :: u8(2)
FILTERED_CHECKED :: u8(3)
CHECKED_NONPRIME :: u8(4)
CHECKED_OTHER_PRIME :: u8(5)

repeated_extra_digits :: proc(value: i64) -> int {
	counts: [10]int = {}
	length := 0
	remaining := value
	for remaining > 0 {
		counts[int(remaining % 10)] += 1
		length += 1
		remaining /= 10
	}
	distinct := 0
	for count in counts { if count > 0 { distinct += 1 } }
	return length - distinct
}

count_digit :: proc(value: i64, digit: i64) -> int {
	count := 0
	remaining := value
	for remaining > 0 {
		if remaining % 10 == digit { count += 1 }
		remaining /= 10
	}
	return count
}

replace_all :: proc(value: i64, digit: i64, replacement: i64) -> i64 {
	result := value
	remaining := value
	place: i64 = 1
	for remaining > 0 {
		if remaining % 10 == digit { result += (replacement - digit) * place }
		remaining /= 10
		place *= 10
	}
	return result
}

@(export)
problem51 :: proc "c" (ignored: i64) -> i64 {
	if ignored != 0 { return -1 }
	state: [PRIME_LIMIT]u8 = {}
	for value := 2; value < PRIME_LIMIT; value += 1 { state[value] = PRIME }
	for prime := 2; prime * prime < PRIME_LIMIT; prime += 1 {
		if state[prime] != PRIME { continue }
		for multiple := prime * prime; multiple < PRIME_LIMIT; multiple += prime { state[multiple] = 0 }
	}
	for value := 2; value < PRIME_LIMIT; value += 1 {
		if state[value] == PRIME && repeated_extra_digits(i64(value)) >= 3 { state[value] = FILTERED_PRIME }
	}
	for number := 2; number < PRIME_LIMIT; number += 1 {
		if state[number] != FILTERED_PRIME { continue }
		place: i64 = 1
		for i64(number) / place >= 10 { place *= 10 }
		seen_digits: [10]bool = {}
		for place > 0 {
			digit := (i64(number) / place) % 10
			if !seen_digits[int(digit)] && count_digit(i64(number), digit) >= 2 {
				seen_digits[int(digit)] = true
				family_count := 0
				family_minimum: i64 = 9223372036854775807
				for replacement := i64(0); replacement <= 9; replacement += 1 {
					member := replace_all(i64(number), digit, replacement)
					if state[member] == FILTERED_PRIME { state[member] = FILTERED_CHECKED }
					else if state[member] == 0 { state[member] = CHECKED_NONPRIME }
					else if state[member] == PRIME { state[member] = CHECKED_OTHER_PRIME }
					if state[member] == FILTERED_PRIME || state[member] == FILTERED_CHECKED {
						family_count += 1
						if member < family_minimum { family_minimum = member }
					}
				}
				if family_count == 8 { return family_minimum }
			}
			place /= 10
		}
	}
	return -1
}
