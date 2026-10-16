module problem51

const prime_limit = 1_000_000
const prime = u8(1)
const filtered_prime = u8(2)
const filtered_checked = u8(3)
const checked_nonprime = u8(4)
const checked_other_prime = u8(5)

fn repeated_extra_digits(value i64) int {
	mut counts := [10]int{}
	mut length := 0
	mut remaining := value
	for remaining > 0 {
		counts[int(remaining % 10)]++
		length++
		remaining /= 10
	}
	mut distinct := 0
	for count in counts { if count > 0 { distinct++ } }
	return length - distinct
}

fn count_digit(value i64, digit i64) int {
	mut count := 0
	mut remaining := value
	for remaining > 0 {
		if remaining % 10 == digit { count++ }
		remaining /= 10
	}
	return count
}

fn replace_all(value i64, digit i64, replacement i64) i64 {
	mut result := value
	mut remaining := value
	mut place := i64(1)
	for remaining > 0 {
		if remaining % 10 == digit { result += (replacement - digit) * place }
		remaining /= 10
		place *= 10
	}
	return result
}

@[export: 'problem51']
pub fn problem51(ignored i64) i64 {
	if ignored != 0 { return -1 }
	mut state := [prime_limit]u8{}
	for value in 2 .. prime_limit { state[value] = prime }
	mut prime_value := 2
	for prime_value * prime_value < prime_limit {
		if state[prime_value] == prime {
			mut multiple := prime_value * prime_value
			for multiple < prime_limit {
				state[multiple] = 0
				multiple += prime_value
			}
		}
		prime_value++
	}
	for value in 2 .. prime_limit {
		if state[value] == prime && repeated_extra_digits(i64(value)) >= 3 { state[value] = filtered_prime }
	}
	for number in 2 .. prime_limit {
		if state[number] != filtered_prime { continue }
		value := i64(number)
		mut place := i64(1)
		for value / place >= 10 { place *= 10 }
		mut seen_digits := [10]bool{}
		for place > 0 {
			digit := value / place % 10
			if !seen_digits[int(digit)] && count_digit(value, digit) >= 2 {
				seen_digits[int(digit)] = true
				mut family_count := 0
				mut family_minimum := i64(9223372036854775807)
				for replacement in 0 .. 10 {
					member := replace_all(value, digit, i64(replacement))
					member_index := int(member)
					if state[member_index] == filtered_prime { state[member_index] = filtered_checked }
					else if state[member_index] == 0 { state[member_index] = checked_nonprime }
					else if state[member_index] == prime { state[member_index] = checked_other_prime }
					if state[member_index] == filtered_prime || state[member_index] == filtered_checked {
						family_count++
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
