module problem77

@[export: 'problem77']
pub fn problem77(threshold i64) i64 {
	if threshold < 0 || threshold > 100_000 { return -1 }
	mut partitions := [100]i64{}
	partitions[0] = 1
	for prime in 2 .. 100 {
		mut is_prime := true
		mut divisor := 2
		for divisor * divisor <= prime {
			if prime % divisor == 0 { is_prime = false; break }
			divisor++
		}
		if is_prime {
			for total in prime .. 100 { partitions[total] += partitions[total - prime] }
		}
	}
	for value in 1 .. 100 { if partitions[value] > threshold { return i64(value) } }
	return -1
}
