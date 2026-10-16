module problem12_sol1

fn divisor_count(value i64) i64 {
	mut remaining := value
	mut factor := i64(2)
	mut count := i64(1)
	for factor <= remaining / factor {
		mut multiplicity := i64(0)
		for remaining % factor == 0 {
			remaining /= factor
			multiplicity++
		}
		if multiplicity > 0 { count *= multiplicity + 1 }
		factor++
	}
	if remaining > 1 { count *= 2 }
	return count
}

@[export: 'problem12_sol1']
pub fn problem12_sol1(threshold i64) i64 {
	if threshold != 500 { return -1 }
	mut index := i64(1)
	mut triangular := i64(1)
	for {
		index++
		triangular += index
		if divisor_count(triangular) > 500 { return triangular }
	}
	return -1
}
