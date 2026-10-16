module problem49

const prime_limit = 10_000

fn digit_signature(value i64) int {
	mut digits := [4]i64{value / 1000, value / 100 % 10, value / 10 % 10, value % 10}
	for first in 0 .. 4 {
		for second in first + 1 .. 4 {
			if digits[first] > digits[second] {
				temporary := digits[first]
				digits[first] = digits[second]
				digits[second] = temporary
			}
		}
	}
	return int(digits[0] * 1000 + digits[1] * 100 + digits[2] * 10 + digits[3])
}

@[export: 'problem49']
pub fn problem49(ignored i64) i64 {
	if ignored != 0 { return -1 }
	mut prime_flags := [prime_limit]bool{}
	for value in 2 .. prime_limit { prime_flags[value] = true }
	mut prime := 2
	for prime * prime < prime_limit {
		if prime_flags[prime] {
			mut multiple := prime * prime
			for multiple < prime_limit {
				prime_flags[multiple] = false
				multiple += prime
			}
		}
		prime++
	}
	mut primes := [1100]i64{}
	mut signatures := [prime_limit]int{}
	mut prime_count := 0
	for value in 1001 .. prime_limit {
		if value % 2 == 1 && prime_flags[value] {
			primes[prime_count] = i64(value)
			prime_count++
			signatures[value] = digit_signature(i64(value))
		}
	}
	mut seen_signatures := [prime_limit]bool{}
	mut best := i64(0)
	for seed in 0 .. prime_count {
		signature := signatures[int(primes[seed])]
		if seen_signatures[signature] { continue }
		seen_signatures[signature] = true
		mut group := [24]i64{}
		mut group_count := 0
		for candidate in 0 .. prime_count {
			value := primes[candidate]
			if signatures[int(value)] == signature {
				group[group_count] = value
				group_count++
			}
		}
		mut found := false
		for first := 0; first < group_count && !found; first++ {
			for second := first + 1; second < group_count && !found; second++ {
				for third := second + 1; third < group_count; third++ {
					if group[second] - group[first] == group[third] - group[second] {
						sequence := group[first] * 100_000_000 + group[second] * 10_000 + group[third]
						if sequence > best { best = sequence }
						found = true
						break
					}
				}
			}
		}
	}
	return best
}
