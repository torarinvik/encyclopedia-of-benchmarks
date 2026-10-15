package main

is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	for factor: i64 = 2; factor <= value / factor; factor += 1 {
		if value % factor == 0 do return false
	}
	return true
}

@(export, link_name="primorial_numbers_sequence")
primorial_numbers_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > 15 do return -1
	product: i64 = 1
	prime_count: i64 = 0
	for candidate: i64 = 2; prime_count < index; candidate += 1 {
		if is_prime(candidate) {
			product *= candidate
			prime_count += 1
		}
	}
	return product
}

main :: proc() {}
