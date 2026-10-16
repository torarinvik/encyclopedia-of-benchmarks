module problem234

@[export: 'problem234']
pub fn problem234(limit i64) i64 {
	if limit < 0 || limit > 999966663333 { return -1 }
	mut composite := [1_000_100]bool{}
	mut primes := [80_000]i64{}
	mut prime_count := 0
	mut root := i64(0)
	for root + 1 <= limit / (root + 1) { root++ }
	sieve_end := int(root) + 100
	for p in 2 .. sieve_end {
		if composite[p] { continue }
		primes[prime_count] = i64(p)
		prime_count++
		if p * p < sieve_end {
			mut multiple := p * p
			for multiple < sieve_end { composite[multiple] = true; multiple += p }
		}
	}
	mut total := i64(0)
	mut index := 0
	mut p := primes[index]
	for p * p <= limit {
		q := primes[index + 1]
		lower := p * p
		mut upper := q * q
		mut current := lower + p
		for upper > current && current <= limit { total += current; current += p }
		for upper - q > limit { upper -= q }
		current = upper - q
		for current > lower { total += current; current -= q }
		current = 0
		for upper > current && current <= limit {
			if current <= lower { current += p * q; continue }
			if current > limit { break }
			total -= current * 2
			current += p * q
		}
		p = q
		index++
	}
	return total
}
