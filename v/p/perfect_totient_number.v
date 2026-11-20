module perfect_totient_number

// Decide whether the iterated Euler-totient chain sums to n.
@[export: 'perfect_totient_number']
pub fn perfect_totient_number(n i64) i64 {
	if n < 3 || n > 65535 { return -1 }
	mut value := n
	mut total := i64(0)
	for value > 1 {
		mut result := value
		mut remaining := value
		mut factor := i64(2)
		for factor <= remaining / factor {
			if remaining % factor == 0 {
				for remaining % factor == 0 { remaining /= factor }
				result -= result / factor
			}
			factor++
		}
		if remaining > 1 { result -= result / remaining }
		value = result
		total += value
	}
	if total == n { return 1 }
	return 0
}
