module sieve_of_sundaram

// Count primes through limit with Sundaram's index sieve.
@[export: 'sieve_of_sundaram']
pub fn sieve_of_sundaram(limit i64) i64 {
	if limit < 0 || limit > 4096 { return -1 }
	if limit < 2 { return 0 }

	max_index := int((limit - 1) / 2)
	mut composite := [2048]bool{init: false}
	mut i := 1
	for 2 * i * (i + 1) <= max_index {
		mut j := i
		for {
			index := i + j + 2 * i * j
			if index > max_index { break }
			composite[index] = true
			j++
		}
		i++
	}

	mut count := i64(1)
	for index in 1 .. max_index + 1 {
		if !composite[index] { count++ }
	}
	return count
}
