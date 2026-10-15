package main

import "core:c"

is_prime_i64 :: proc(n: i64) -> bool {
	if n < 2 do return false
	if n % 2 == 0 do return n == 2
	factor: i64 = 3
	for factor <= n / factor {
		if n % factor == 0 do return false
		factor += 2
	}
	return true
}

@(export, link_name="mersenne_prime")
mersenne_prime :: proc(n: i64) -> i64 {
	if n == 0 do return 0
	if n < 0 || n > 2147483647 do return -1
	remaining := n + 1
	for remaining % 2 == 0 {
		remaining /= 2
	}
	if remaining != 1 do return 0
	return i64(is_prime_i64(n))
}

main :: proc() {}
