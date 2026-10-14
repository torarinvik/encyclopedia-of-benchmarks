package sieve_of_atkin

// Count primes through limit with the Sieve of Atkin.
@(export)
sieve_of_atkin :: proc "c" (limit: i64) -> i64 {
	if limit < 0 || limit > 4096 do return -1
	if limit < 2 do return 0
	n := int(limit)
	var_sieve: [4097]bool
	for index := 0; index < 4097; index += 1 { var_sieve[index] = false }
	for x := 1; x <= n / x; x += 1 {
		x2 := x * x
		for y := 1; y <= n / y; y += 1 {
			y2 := y * y
			first := 4 * x2 + y2
			if first <= n && (first % 12 == 1 || first % 12 == 5) { var_sieve[first] = !var_sieve[first] }
			second := 3 * x2 + y2
			if second <= n && second % 12 == 7 { var_sieve[second] = !var_sieve[second] }
			if x > y {
				third := 3 * x2 - y2
				if third <= n && third % 12 == 11 { var_sieve[third] = !var_sieve[third] }
			}
		}
	}
	for candidate := 5; candidate <= n / candidate; candidate += 1 {
		if var_sieve[candidate] {
			square := candidate * candidate
			for multiple := square; multiple <= n; multiple += square { var_sieve[multiple] = false }
		}
	}
	count := i64(1)
	if n >= 3 do count += 1
	for value := 5; value <= n; value += 1 {
		if var_sieve[value] do count += 1
	}
	return count
}
