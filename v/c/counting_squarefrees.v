module counting_squarefrees

const max_n = i64(1_000_000_000_000)
const max_root = 1_000_000

fn integer_sqrt(value i64) i64 {
	mut low := i64(1)
	mut high := i64(max_root)
	for low < high {
		middle := low + (high - low + 1) / 2
		if middle <= value / middle { low = middle } else { high = middle - 1 }
	}
	return low
}

@[export: 'counting_squarefrees']
pub fn counting_squarefrees(n i64) i64 {
	if n < 1 || n > max_n { return -1 }
	limit := int(integer_sqrt(n))
	mut mobius := []u8{len: max_root + 1, init: 0}
	mut composite := []bool{len: max_root + 1, init: false}
	for value in 1 .. limit + 1 { mobius[value] = 1 }

	for prime in 2 .. limit + 1 {
		if composite[prime] { continue }
		if prime <= limit / prime {
			mut mark_multiple := prime * prime
			for mark_multiple <= limit {
				composite[mark_multiple] = true
				mark_multiple += prime
			}
		}
		mut factor_multiple := prime
		for factor_multiple <= limit {
			if mobius[factor_multiple] == 1 { mobius[factor_multiple] = 2 }
			else if mobius[factor_multiple] == 2 { mobius[factor_multiple] = 1 }
			factor_multiple += prime
		}
		if prime <= limit / prime {
			square := prime * prime
			mut square_multiple := square
			for square_multiple <= limit {
				mobius[square_multiple] = 0
				square_multiple += square
			}
		}
	}

	mut count := i64(0)
	for divisor in 1 .. limit + 1 {
		d := i64(divisor)
		quotient := n / (d * d)
		if mobius[divisor] == 1 { count += quotient }
		else if mobius[divisor] == 2 { count -= quotient }
	}
	return count
}
