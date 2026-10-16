package problem49

digit_signature :: proc(value: i64) -> i64 {
	digits := [4]i64{value / 1000, value / 100 % 10, value / 10 % 10, value % 10}
	for first := 0; first < 4; first += 1 {
		for second := first + 1; second < 4; second += 1 {
			if digits[first] > digits[second] {
				temporary := digits[first]
				digits[first] = digits[second]
				digits[second] = temporary
			}
		}
	}
	return digits[0] * 1000 + digits[1] * 100 + digits[2] * 10 + digits[3]
}

@(export)
problem49 :: proc "c" (ignored: i64) -> i64 {
	if ignored != 0 { return -1 }
	prime_flags: [10000]bool = {}
	for value := 2; value < 10000; value += 1 { prime_flags[value] = true }
	for prime := 2; prime * prime < 10000; prime += 1 {
		if !prime_flags[prime] { continue }
		for multiple := prime * prime; multiple < 10000; multiple += prime { prime_flags[multiple] = false }
	}
	primes: [1100]i64 = {}
	signatures: [10000]i64 = {}
	prime_count := 0
	for value := 1001; value < 10000; value += 2 {
		if prime_flags[value] {
			primes[prime_count] = i64(value)
			prime_count += 1
			signatures[value] = digit_signature(i64(value))
		}
	}
	seen_signatures: [10000]bool = {}
	best: i64 = 0
	for seed := 0; seed < prime_count; seed += 1 {
		signature := int(signatures[primes[seed]])
		if seen_signatures[signature] { continue }
		seen_signatures[signature] = true
		group: [24]i64 = {}
		group_count := 0
		for candidate := 0; candidate < prime_count; candidate += 1 {
			value := primes[candidate]
			if signatures[value] == i64(signature) {
				group[group_count] = value
				group_count += 1
			}
		}
		found := false
		for first := 0; first < group_count && !found; first += 1 {
			for second := first + 1; second < group_count && !found; second += 1 {
				for third := second + 1; third < group_count; third += 1 {
					if group[second] - group[first] == group[third] - group[second] {
						sequence := group[first] * 100000000 + group[second] * 10000 + group[third]
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
