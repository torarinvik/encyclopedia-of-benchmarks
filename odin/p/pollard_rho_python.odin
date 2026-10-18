package pollard_rho_python

import "core:c"

MAX_NUM :: i64(1_000_000)

gcd_nonnegative :: proc(left_value, right_value: i64) -> i64 {
	left := left_value
	right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

advance :: proc(value, step, modulus: i64) -> i64 {
	return (value * value + step) % modulus
}

@(export)
pollard_rho_python :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 5 do return -1
	num := input[0]
	seed := input[1]
	step := input[2]
	attempts := input[3]
	step_limit := input[4]
	if num < 2 || num > MAX_NUM || seed < 0 || seed >= num || step < 0 || step > 1000 || attempts < 1 || attempts > 8 || step_limit < 1 || step_limit > 64 do return -1
	if num > 2 && num % 2 == 0 do return 2

	for attempt: i64 = 0; attempt < attempts; attempt += 1 {
		tortoise := seed
		hare := seed
		for iteration: i64 = 0; iteration < step_limit; iteration += 1 {
			tortoise = advance(tortoise, step, num)
			hare = advance(advance(hare, step, num), step, num)
			difference := hare - tortoise
			if difference < 0 do difference = -difference
			divisor := gcd_nonnegative(difference, num)
			if divisor == 1 do continue
			if divisor < num do return divisor
			break
		}
		seed = hare
		step += 1
	}
	return 0
}
