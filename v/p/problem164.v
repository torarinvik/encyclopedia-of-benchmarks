module problem164

@[export: 'problem164']
pub fn problem164(n_digits i64) i64 {
	if n_digits < 0 || n_digits > 26 { return -1 }
	if n_digits == 0 { return 1 }
	mut current := [100]i64{}
	mut next := [100]i64{}
	for first in 1 .. 10 { current[first * 10] = 1 }
	for _ in 1 .. int(n_digits) {
		for index in 0 .. 100 { next[index] = 0 }
		for previous in 0 .. 10 {
			for before_previous in 0 .. 10 {
				ways := current[previous * 10 + before_previous]
				maximum_digit := 9 - previous - before_previous
				for digit in 0 .. maximum_digit + 1 {
					next[digit * 10 + previous] += ways
				}
			}
		}
		for index in 0 .. 100 { current[index] = next[index] }
	}
	mut total := i64(0)
	for ways in current { total += ways }
	return total
}
