module elliptic_curve_method_stage1

const stage1_primes = [11]i64{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31}

struct XPoint {
mut:
	x i64
	z i64
}

fn mod_norm(value_input i64, modulus i64) i64 {
	mut value := value_input % modulus
	if value < 0 { value += modulus }
	return value
}

fn gcd_i64(left_input i64, right_input i64) i64 {
	mut left := left_input.abs()
	mut right := right_input.abs()
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn square_free(number i64) bool {
	mut divisor := i64(2)
	for divisor * divisor <= number {
		if number % (divisor * divisor) == 0 { return false }
		divisor++
	}
	return true
}

fn x_double(point XPoint, a24 i64, modulus i64) XPoint {
	plus := mod_norm(point.x + point.z, modulus)
	minus := mod_norm(point.x - point.z, modulus)
	plus_sq := plus * plus % modulus
	minus_sq := minus * minus % modulus
	delta := mod_norm(plus_sq - minus_sq, modulus)
	return XPoint{
		x: plus_sq * minus_sq % modulus
		z: delta * mod_norm(minus_sq + a24 * delta, modulus) % modulus
	}
}

fn x_add(left XPoint, right XPoint, difference XPoint, modulus i64) XPoint {
	first := mod_norm(left.x - left.z, modulus) * mod_norm(right.x + right.z, modulus) % modulus
	second := mod_norm(left.x + left.z, modulus) * mod_norm(right.x - right.z, modulus) % modulus
	sum_term := mod_norm(first + second, modulus)
	difference_term := mod_norm(first - second, modulus)
	return XPoint{
		x: difference.z * sum_term % modulus * sum_term % modulus
		z: difference.x * difference_term % modulus * difference_term % modulus
	}
}

fn x_multiply(point XPoint, scalar i64, a24 i64, modulus i64) XPoint {
	mut r0 := XPoint{x: 1, z: 0}
	mut r1 := point
	mut copy := scalar
	mut highest := 0
	for copy > 1 { copy >>= 1; highest++ }
	mut bit := highest
	for bit >= 0 {
		if (scalar & (i64(1) << bit)) != 0 {
			r0 = x_add(r0, r1, point, modulus)
			r1 = x_double(r1, a24, modulus)
		} else {
			r1 = x_add(r0, r1, point, modulus)
			r0 = x_double(r0, a24, modulus)
		}
		bit--
	}
	return r0
}

@[export: 'elliptic_curve_method_stage1']
pub fn elliptic_curve_method_stage1(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 5 { return -1 }
	unsafe {
		number := input[0]
		curve_a := input[1]
		point_x := input[2]
		point_y := input[3]
		bound := input[4]
		if number < 3 || number > 10000 || number % 2 == 0 || bound < 2 || bound > 32 { return -1 }
		if curve_a < 0 || curve_a >= number || point_x < 0 || point_x >= number || point_y < 0 || point_y >= number { return -1 }
		if !square_free(number) || gcd_i64(curve_a * curve_a - 4, number) != 1 { return -1 }
		x_sq := point_x * point_x % number
		rhs := (x_sq * point_x + curve_a * x_sq + point_x) % number
		if point_y * point_y % number != rhs { return -1 }
		inverse_four := if number % 4 == 3 { (number + 1) / 4 } else { (3 * number + 1) / 4 }
		a24 := (curve_a + 2) * inverse_four % number
		mut point := XPoint{x: point_x, z: 1}
		for prime in stage1_primes {
			if prime > bound { break }
			mut prime_power := prime
			for prime_power <= bound / prime { prime_power *= prime }
			point = x_multiply(point, prime_power, a24, number)
			divisor := gcd_i64(point.z, number)
			if divisor > 1 {
				if divisor < number { return 1 }
				return 0
			}
		}
		return 0
	}
}
