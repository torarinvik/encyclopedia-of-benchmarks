package elliptic_curve_method_stage1

import "core:c"

STAGE1_PRIMES :: [11]i64{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31}

X_Point :: struct {x, z: i64}

mod_norm :: proc(value_input, modulus: i64) -> i64 {
	value := value_input % modulus
	if value < 0 { value += modulus }
	return value
}

gcd_i64 :: proc(left_input, right_input: i64) -> i64 {
	left, right := left_input, right_input
	if left < 0 { left = -left }
	if right < 0 { right = -right }
	for right != 0 {
		remainder := left % right
		left, right = right, remainder
	}
	return left
}

square_free :: proc(number: i64) -> bool {
	for divisor: i64 = 2; divisor * divisor <= number; divisor += 1 {
		if number % (divisor * divisor) == 0 { return false }
	}
	return true
}

x_double :: proc(point: X_Point, a24, modulus: i64) -> X_Point {
	plus := mod_norm(point.x + point.z, modulus)
	minus := mod_norm(point.x - point.z, modulus)
	plus_sq := plus * plus % modulus
	minus_sq := minus * minus % modulus
	delta := mod_norm(plus_sq - minus_sq, modulus)
	return {plus_sq * minus_sq % modulus, delta * mod_norm(minus_sq + a24 * delta, modulus) % modulus}
}

x_add :: proc(left, right, difference: X_Point, modulus: i64) -> X_Point {
	first := mod_norm(left.x - left.z, modulus) * mod_norm(right.x + right.z, modulus) % modulus
	second := mod_norm(left.x + left.z, modulus) * mod_norm(right.x - right.z, modulus) % modulus
	sum_term := mod_norm(first + second, modulus)
	difference_term := mod_norm(first - second, modulus)
	return {difference.z * sum_term % modulus * sum_term % modulus,
	        difference.x * difference_term % modulus * difference_term % modulus}
}

x_multiply :: proc(point: X_Point, scalar, a24, modulus: i64) -> X_Point {
	r0 := X_Point{1, 0}
	r1 := point
	copy := scalar
	highest := 0
	for copy > 1 { copy >>= 1; highest += 1 }
	for bit := highest; bit >= 0; bit -= 1 {
		if (scalar & (i64(1) << bit)) != 0 {
			r0 = x_add(r0, r1, point, modulus)
			r1 = x_double(r1, a24, modulus)
		} else {
			r1 = x_add(r0, r1, point, modulus)
			r0 = x_double(r0, a24, modulus)
		}
	}
	return r0
}

@(export)
elliptic_curve_method_stage1 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 5 do return -1
	number, curve_a, point_x, point_y, bound := input[0], input[1], input[2], input[3], input[4]
	if number < 3 || number > 10_000 || (number & 1) == 0 || bound < 2 || bound > 32 do return -1
	if curve_a < 0 || curve_a >= number || point_x < 0 || point_x >= number || point_y < 0 || point_y >= number do return -1
	if !square_free(number) || gcd_i64(curve_a * curve_a - 4, number) != 1 do return -1
	x_sq := point_x * point_x % number
	rhs := (x_sq * point_x + curve_a * x_sq + point_x) % number
	if point_y * point_y % number != rhs do return -1
	inverse_four := (number + 1) / 4 if number % 4 == 3 else (3 * number + 1) / 4
	a24 := (curve_a + 2) * inverse_four % number
	point := X_Point{point_x, 1}
	for prime in STAGE1_PRIMES {
		if prime > bound do break
		prime_power := prime
		for prime_power <= bound / prime { prime_power *= prime }
		point = x_multiply(point, prime_power, a24, number)
		divisor := gcd_i64(point.z, number)
		if divisor > 1 {
			if divisor < number do return 1
			return 0
		}
	}
	return 0
}
