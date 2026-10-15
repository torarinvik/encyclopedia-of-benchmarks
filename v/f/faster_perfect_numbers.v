module faster_perfect_numbers

const max_input = i64(2305843009213693951)

fn get_prime_limit(value i64) u64 {
	mut scaled := u64(value) * u64(8) + u64(1)
	mut limit := u64(0)
	for scaled >= 4 {
		scaled /= 4
		limit++
	}
	return limit
}

fn is_prime(value u64) bool {
	if value < 2 { return false }
	mut divisor := u64(2)
	for divisor * divisor <= value {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn is_mersenne_prime(exponent u64) bool {
	if exponent == 2 { return true }
	if exponent < 2 { return false }
	modulus := (u64(1) << u32(exponent)) - u64(1)
	mut residue := u64(4)
	for iteration := u64(0); iteration < exponent - 2; iteration++ {
		residue = (residue * residue - u64(2)) % modulus
	}
	return residue == 0
}

@[export: 'faster_perfect_numbers']
pub fn faster_perfect_numbers(value i64, mut output &u8, output_capacity usize) i64 {
	if value < 0 || value > max_input { return -1 }
	mut perfects := [8]i64{}
	mut count := 0
	limit := get_prime_limit(value)
	mut exponent := u64(2)
	for exponent <= limit {
		if is_prime(exponent) && is_mersenne_prime(exponent) {
			mersenne := (u64(1) << u32(exponent)) - u64(1)
			perfect := mersenne * (u64(1) << u32(exponent - 1))
			if perfect <= u64(value) {
				perfects[count] = i64(perfect)
				count++
			}
		}
		exponent++
	}
	required := usize(count * 8)
	if output_capacity < required { return -2 }
	for index in 0 .. count {
		mut bits := u64(perfects[index])
		for byte in 0 .. 8 {
			unsafe { output[index * 8 + byte] = u8(bits & u64(255)) }
			bits >>= 8
		}
	}
	return i64(required)
}
