module factorize

fn factor_pairs(value i64, mut primes []u32, mut exponents []u32) int {
    if value <= 1 {
        primes[0] = u32(value)
        exponents[0] = 1
        return 1
    }
	mut count := 0
	mut remaining := value
	mut divisor := i64(2)
	for divisor <= remaining / divisor {
		if remaining % divisor == 0 {
			mut exponent := u32(0)
			for remaining % divisor == 0 {
				remaining /= divisor
				exponent++
			}
			primes[count] = u32(divisor)
			exponents[count] = exponent
			count++
		}
		divisor++
	}
	if remaining > 1 {
		primes[count] = u32(remaining)
		exponents[count] = 1
		count++
	}
	return count
}

fn write_u32le(value u32, mut output &u8, position int) {
	for byte in 0 .. 4 {
		unsafe { output[position + byte] = u8((value >> (8 * byte)) & 255) }
	}
}

// Encode ascending prime/exponent pairs as little-endian u32 values.
@[export: 'factorize']
pub fn factorize(value i64, mut output &u8, output_capacity usize) i64 {
	if value < 0 || value > 1000005 { return -1 }
	mut primes := []u32{len: 10}
	mut exponents := []u32{len: 10}
	count := factor_pairs(value, mut primes, mut exponents)
	required := count * 8
	if output_capacity < usize(required) { return -2 }
	for index in 0 .. count {
		write_u32le(primes[index], mut output, 8 * index)
		write_u32le(exponents[index], mut output, 8 * index + 4)
	}
	return i64(required)
}
