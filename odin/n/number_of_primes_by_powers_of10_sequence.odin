package main

is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	for factor: i64 = 2; factor <= value / factor; factor += 1 {
		if value % factor == 0 do return false
	}
	return true
}

@(export, link_name="number_of_primes_by_powers_of10_sequence")
number_of_primes_by_powers_of10_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > 3 do return -1
	if index == 0 do return 0
	upper: i64 = 10
	for i: i64 = 1; i < index; i += 1 {
		upper *= 10
	}
	count: i64 = 0
	for value: i64 = 2; value < upper; value += 1 {
		if is_prime(value) do count += 1
	}
	return count
}

main :: proc() {}
