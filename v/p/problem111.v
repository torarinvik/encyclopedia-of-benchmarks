module problem111

fn is_prime(value i64, primes []i64) bool {
	for p in primes { if value % p == 0 { return false } }
	return true
}

@[export: 'problem111']
pub fn problem111(n i64) i64 {
	if n < 1000 || n > 10_000_000_000 { return -1 }
	mut composite := [100_002]bool{}
	mut primes := [100_001]i64{}
	mut prime_count := 0
	mut root := i64(0)
	for root + 1 <= n / (root + 1) { root++ }
	sieve_limit := int(root) + 1
	for p in 2 .. sieve_limit + 1 {
		if composite[p] { continue }
		primes[prime_count] = i64(p); prime_count++
		if p * p <= sieve_limit { mut multiple := p * p; for multiple <= sieve_limit { composite[multiple] = true; multiple += p } }
	}
	mut digits := 0; mut copy := n; for copy > 0 { digits++; copy /= 10 }
	width := digits - 1; repeated_two := width - 2; prime_slice := primes[..prime_count]
	mut total := i64(0)
	for i in 1 .. 10 { for j in 1 .. 10 { mut value := i64(i); for _ in 0 .. width - 2 { value *= 10 }; value = value * 10 + i64(j); if is_prime(value, prime_slice) { total += value } } }
	mut one_digit := [10]bool{}
	for i in 1 .. 10 { for j in 0 .. width { for k in 0 .. 10 {
		mut value := i64(0); for pos in 0 .. width { mut digit := i; if pos == j { digit = k }; value = value * 10 + i64(digit) }
		if is_prime(value, prime_slice) { one_digit[i] = true; total += value }
	} } }
	for i in 1 .. 10 { if one_digit[i] { continue }; for j in 0 .. repeated_two + 1 { for k in 0 .. repeated_two - j + 1 { for m1 in 0 .. 10 {
		if m1 == 0 && j == 0 { continue }
		for m2 in 0 .. 10 { mut value := i64(0); for pos in 0 .. width { mut digit := i; if pos == j { digit = m1 } else if pos == j + k + 1 { digit = m2 }; value = value * 10 + i64(digit) }; if is_prime(value, prime_slice) { total += value } }
	} } } }
	return total
}
