module cornacchia_x2_plus_2y2

const max_prime = i64(1_000_000)
const pack_base = i64(1024)

fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor <= value/divisor {
		if value % divisor == 0 { return false }
		if divisor == 2 { divisor = 3 } else { divisor += 2 }
	}
	return true
}

fn isqrt(value i64) i64 {
	mut low := i64(0)
	mut high := i64(1001)
	for low+1 < high {
		middle := (low+high)/2
		if middle*middle <= value { low = middle } else { high = middle }
	}
	return low
}

@[export: 'cornacchia_x2_plus_2y2']
pub fn cornacchia_x2_plus_2y2(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		prime := input[0]
		root := input[1]
		if prime < 3 || prime > max_prime || (prime & 1) == 0 || root < 1 || root > prime/2 { return -1 }
		if !is_prime(prime) || (root*root+2)%prime != 0 { return -1 }

		mut previous := prime
		mut current := root
		limit := isqrt(prime)
		for current > limit {
			remainder := previous%current
			previous = current
			current = remainder
		}
		x := current
		numerator := prime-x*x
		if numerator <= 0 || numerator%2 != 0 { return -1 }
		y_squared := numerator/2
		y := isqrt(y_squared)
		if y <= 0 || y*y != y_squared || x*x+2*y*y != prime { return -1 }
		return x*pack_base+y
	}
}
