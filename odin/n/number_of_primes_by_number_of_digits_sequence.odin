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

@(export, link_name="number_of_primes_by_number_of_digits_sequence")
number_of_primes_by_number_of_digits_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > 3 do return -1
	if index == 0 do return 0
	lower: i64 = 1
	for i: i64 = 1; i < index; i += 1 {
		lower *= 10
	}
	upper := lower * 10
	count: i64 = 0
	for value := lower + 1; value <= upper; value += 1 {
		if is_prime(value) do count += 1
	}
	return count
}

main :: proc() {}
