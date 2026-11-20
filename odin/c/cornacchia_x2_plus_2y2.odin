package cornacchia_x2_plus_2y2

import "core:c"

MAX_PRIME :: i64(1_000_000)
MAX_LENGTH :: 3
PACK_BASE :: i64(1024)

is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	divisor := i64(2)
	for divisor <= value/divisor {
		if value % divisor == 0 do return false
		if divisor == 2 { divisor = 3 } else { divisor += 2 }
	}
	return true
}

isqrt :: proc(value: i64) -> i64 {
	low := i64(0)
	high := i64(1001)
	for low+1 < high {
		middle := (low+high)/2
		if middle*middle <= value { low = middle } else { high = middle }
	}
	return low
}

@(export)
cornacchia_x2_plus_2y2 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	prime := input[0]
	root := input[1]
	if prime < 3 || prime > MAX_PRIME || (prime & 1) == 0 || root < 1 || root > prime/2 do return -1
	if !is_prime(prime) || (root*root+2)%prime != 0 do return -1

	previous := prime
	current := root
	limit := isqrt(prime)
	for current > limit {
		remainder := previous%current
		previous = current
		current = remainder
	}
	x := current
	numerator := prime-x*x
	if numerator <= 0 || numerator%2 != 0 do return -1
	y_squared := numerator/2
	y := isqrt(y_squared)
	if y <= 0 || y*y != y_squared || x*x+2*y*y != prime do return -1
	return x*PACK_BASE+y
}
