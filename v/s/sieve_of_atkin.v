module sieve_of_atkin

// Count primes through limit with the Sieve of Atkin.
@[export: 'sieve_of_atkin']
pub fn sieve_of_atkin(limit i64) i64 {
	if limit < 0 || limit > 4096 { return -1 }
	if limit < 2 { return 0 }
	n := int(limit)
	mut sieve := [4097]bool{init: false}
	mut x := 1
	for x <= n / x {
		x2 := x * x
		mut y := 1
		for y <= n / y {
			y2 := y * y
			first := 4 * x2 + y2
			if first <= n && (first % 12 == 1 || first % 12 == 5) { sieve[first] = !sieve[first] }
			second := 3 * x2 + y2
			if second <= n && second % 12 == 7 { sieve[second] = !sieve[second] }
			if x > y {
				third := 3 * x2 - y2
				if third <= n && third % 12 == 11 { sieve[third] = !sieve[third] }
			}
			y++
		}
		x++
	}
	mut candidate := 5
	for candidate <= n / candidate {
		if sieve[candidate] {
			square := candidate * candidate
			mut multiple := square
			for multiple <= n {
				sieve[multiple] = false
				multiple += square
			}
		}
		candidate++
	}
	mut count := i64(1)
	if n >= 3 { count++ }
	for value in 5 .. n + 1 {
		if sieve[value] { count++ }
	}
	return count
}
