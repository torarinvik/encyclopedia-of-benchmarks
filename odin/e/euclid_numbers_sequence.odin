package main

is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	factor: i64 = 2
	for factor <= value / factor {
		if value % factor == 0 do return false
		factor += 1
	}
	return true
}

@(export, link_name="euclid_numbers_sequence")
euclid_numbers_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > 15 do return -1
	product: i64 = 1
	prime_count: i64 = 0
	for candidate: i64 = 2; prime_count < index + 1; candidate += 1 {
		if is_prime(candidate) {
			product *= candidate
			prime_count += 1
		}
	}
	return product + 1
}

main :: proc() {}
