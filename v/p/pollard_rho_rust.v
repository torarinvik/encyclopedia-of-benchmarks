const max_num = i64(1_000_000_000)
const u32_mod = i64(4_294_967_296)
const batch = i64(32)
const cutoff = i64(262_144)

fn gcd_nonnegative(mut left i64, mut right i64) i64 {
	for left != 0 {
		remainder := right % left
		right = left
		left = remainder
	}
	return right
}

fn mod_power(base_value i64, power_value i64, modulus i64) i64 {
	mut base := base_value % modulus
	mut power := power_value
	if base == 0 { return 0 }
	mut result := i64(1)
	for power > 0 {
		if power % 2 != 0 { result = result * base % modulus }
		base = base * base % modulus
		power /= 2
	}
	return result
}

fn passes_base(number i64, base i64) bool {
	mut odd_power := number - 1
	mut two_power := i64(0)
	for odd_power % 2 == 0 {
		odd_power /= 2
		two_power++
	}
	mut value := mod_power(base, odd_power, number)
	if value == 1 || value == number - 1 { return true }
	for _ in 1 .. int(two_power) {
		value = value * value % number
		if value == number - 1 { return true }
	}
	return false
}

fn probable_prime(number i64) bool {
	if number <= 4 { return number == 2 || number == 3 }
	if number == 5 || number == 7 { return true }
	return passes_base(number, 2) && passes_base(number, 3) && passes_base(number, 5) && passes_base(number, 7)
}

fn advance(x i64, c i64, number i64) i64 { return (x * x + c) % number }

fn brent_factor(number i64, x0 i64, c i64) i64 {
	mut x := x0
	mut x_start := i64(0)
	mut y := i64(0)
	mut remainder := i64(1)
	mut current_gcd := i64(1)
	mut max_iterations := i64(1)
	for current_gcd == 1 {
		y = x
		for _ in 1 .. int(max_iterations) { x = advance(x, c, number) }
		mut big_iteration := i64(0)
		for big_iteration < max_iterations && current_gcd == 1 {
			x_start = x
			mut small_iteration := i64(0)
			for small_iteration < batch && small_iteration < max_iterations - big_iteration {
				small_iteration++
				x = advance(x, c, number)
				mut difference := x - y
				if difference < 0 { difference = -difference }
				remainder = remainder * difference % number
			}
			current_gcd = gcd_nonnegative(remainder, number)
			big_iteration += batch
		}
		max_iterations *= 2
		if max_iterations > cutoff { break }
	}
	if current_gcd == number {
		for current_gcd == 1 {
			x_start = advance(x_start, c, number)
			mut difference := x_start - y
			if difference < 0 { difference = -difference }
			current_gcd = gcd_nonnegative(difference, number)
		}
	}
	return current_gcd
}

@[export: 'pollard_rho_rust']
pub fn pollard_rho_rust(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 3 { return -1 }
	unsafe {
		number := input[0]
		mut state := input[1]
		restart_limit := input[2]
		if number < 2 || number > max_num || state < 0 || state >= u32_mod || restart_limit < 1 || restart_limit > 16 { return -1 }
		if probable_prime(number) { return number }

		for _ in 0 .. int(restart_limit) {
			state = (1_103_515_245 * state + 12_345) % u32_mod
			high_x := state
			state = (1_103_515_245 * state + 12_345) % u32_mod
			low_x := state
			x_mod := number - 3
			x0 := ((high_x % x_mod) * (u32_mod % x_mod) + low_x % x_mod) % x_mod + 2
			state = (1_103_515_245 * state + 12_345) % u32_mod
			high_c := state
			state = (1_103_515_245 * state + 12_345) % u32_mod
			low_c := state
			c_mod := number - 2
			c := ((high_c % c_mod) * (u32_mod % c_mod) + low_c % c_mod) % c_mod + 1
			factor := brent_factor(number, x0, c)
			if factor != 1 && factor != number { return factor }
		}
		return 0
	}
}
