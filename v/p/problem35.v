module problem35

const max_limit = 1_000_000
const odd_slots = max_limit / 2 + 1

@[export: 'problem35']
pub fn problem35(ignored i64) i64 {
	if ignored != 0 { return -1 }
	mut odd_prime := [odd_slots]bool{}
	for index in 1 .. odd_slots { odd_prime[index] = true }

	mut candidate := 3
	for candidate <= max_limit / candidate {
		if odd_prime[candidate / 2] {
			mut composite := candidate * candidate
			for composite <= max_limit {
				odd_prime[composite / 2] = false
				composite += 2 * candidate
			}
		}
		candidate += 2
	}

	mut count := i64(1)
	mut number := 3
	for number <= max_limit {
		if odd_prime[number / 2] {
			mut remaining := number
			mut has_even_digit := false
			for remaining > 0 {
				if (remaining % 10) % 2 == 0 {
					has_even_digit = true
					break
				}
				remaining /= 10
			}
			if !has_even_digit {
				mut power10 := 1
				mut digits := 1
				remaining = number
				for remaining >= 10 {
					power10 *= 10
					remaining /= 10
					digits++
				}
				mut rotation := number
				mut circular := true
				for _ in 0 .. digits {
					if !odd_prime[rotation / 2] {
						circular = false
						break
					}
					rotation = (rotation % 10) * power10 + rotation / 10
				}
				if circular { count++ }
			}
		}
		number += 2
	}
	return count
}
