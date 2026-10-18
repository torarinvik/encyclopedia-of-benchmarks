package pollard_rho_rust

import "core:c"

MAX_NUM :: i64(1_000_000_000)
U32_MOD :: i64(4_294_967_296)
BATCH :: i64(32)
CUTOFF :: i64(262_144)

gcd_nonnegative :: proc(left_value, right_value: i64) -> i64 {
	left := left_value
	right := right_value
	for left != 0 {
		remainder := right % left
		right = left
		left = remainder
	}
	return right
}

mod_power :: proc(base_value, power_value, modulus: i64) -> i64 {
	base := base_value % modulus
	power := power_value
	if base == 0 do return 0
	result := i64(1)
	for power > 0 {
		if power % 2 != 0 do result = result * base % modulus
		base = base * base % modulus
		power /= 2
	}
	return result
}

passes_base :: proc(number, base: i64) -> bool {
	odd_power := number - 1
	two_power := i64(0)
	for odd_power % 2 == 0 {
		odd_power /= 2
		two_power += 1
	}
	value := mod_power(base, odd_power, number)
	if value == 1 || value == number - 1 do return true
	for r: i64 = 1; r < two_power; r += 1 {
		value = value * value % number
		if value == number - 1 do return true
	}
	return false
}

probable_prime :: proc(number: i64) -> bool {
	if number <= 4 do return number == 2 || number == 3
	if number == 5 || number == 7 do return true
	return passes_base(number, 2) && passes_base(number, 3) && passes_base(number, 5) && passes_base(number, 7)
}

advance :: proc(x, c, number: i64) -> i64 { return (x * x + c) % number }

brent_factor :: proc(number, x0, c: i64) -> i64 {
	x := x0
	x_start := i64(0)
	y := i64(0)
	remainder := i64(1)
	current_gcd := i64(1)
	max_iterations := i64(1)
	for current_gcd == 1 {
		y = x
		for i: i64 = 1; i < max_iterations; i += 1 { x = advance(x, c, number) }
		big_iteration := i64(0)
		for big_iteration < max_iterations && current_gcd == 1 {
			x_start = x
			small_iteration := i64(0)
			for small_iteration < BATCH && small_iteration < max_iterations - big_iteration {
				small_iteration += 1
				x = advance(x, c, number)
				difference := x - y
				if difference < 0 do difference = -difference
				remainder = remainder * difference % number
			}
			current_gcd = gcd_nonnegative(remainder, number)
			big_iteration += BATCH
		}
		max_iterations *= 2
		if max_iterations > CUTOFF do break
	}
	if current_gcd == number {
		for current_gcd == 1 {
			x_start = advance(x_start, c, number)
			difference := x_start - y
			if difference < 0 do difference = -difference
			current_gcd = gcd_nonnegative(difference, number)
		}
	}
	return current_gcd
}

@(export)
pollard_rho_rust :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	number := input[0]
	state := input[1]
	restart_limit := input[2]
	if number < 2 || number > MAX_NUM || state < 0 || state >= U32_MOD || restart_limit < 1 || restart_limit > 16 do return -1
	if probable_prime(number) do return number

	for restart: i64 = 0; restart < restart_limit; restart += 1 {
		state = (1_103_515_245 * state + 12_345) % U32_MOD
		high_x := state
		state = (1_103_515_245 * state + 12_345) % U32_MOD
		low_x := state
		x_mod := number - 3
		x0 := ((high_x % x_mod) * (U32_MOD % x_mod) + low_x % x_mod) % x_mod + 2
		state = (1_103_515_245 * state + 12_345) % U32_MOD
		high_c := state
		state = (1_103_515_245 * state + 12_345) % U32_MOD
		low_c := state
		c_mod := number - 2
		c := ((high_c % c_mod) * (U32_MOD % c_mod) + low_c % c_mod) % c_mod + 1
		factor := brent_factor(number, x0, c)
		if factor != 1 && factor != number do return factor
	}
	return 0
}
