module mobius_function

@[export: 'mobius_function']
pub fn mobius_function(n i64) i64 {
	if n < 1 || n > 10000 { return -9223372036854775807 - 1 }
	mut remaining := n
	mut distinct_factor_count := i64(0)
	mut factor := i64(2)
	for factor * factor <= remaining {
		if remaining % factor == 0 {
			remaining /= factor
			if remaining % factor == 0 { return 0 }
			distinct_factor_count++
		}
		factor++
	}
	if remaining > 1 { distinct_factor_count++ }
	if distinct_factor_count % 2 == 0 { return 1 }
	return -1
}
