package problem77

@(export)
problem77 :: proc "c" (threshold: i64) -> i64 {
	if threshold < 0 || threshold > 100_000 do return -1
	partitions: [100]i64 = {}
	partitions[0] = 1
	for prime := i64(2); prime < 100; prime += 1 {
		is_prime := true
		for divisor := i64(2); divisor * divisor <= prime; divisor += 1 {
			if prime % divisor == 0 { is_prime = false; break }
		}
		if is_prime {
			for total := prime; total < 100; total += 1 { partitions[total] += partitions[total - prime] }
		}
	}
	for value := i64(1); value < 100; value += 1 {
		if partitions[value] > threshold do return value
	}
	return -1
}
