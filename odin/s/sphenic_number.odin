package sphenic_number

source_sieve_flag :: proc(value: i64) -> bool {
	if value < 2 do return true
	for divisor := i64(2); divisor <= value / divisor; divisor += 1 {
		if value % divisor == 0 do return false
	}
	return true
}

@(export)
sphenic_number :: proc "c" (value: i64) -> i64 {
	if value < 0 || value > 1000 do return -1
	first: [3]i64
	count: i64 = 0
	for divisor := i64(1); divisor <= value; divisor += 1 {
		if value % divisor == 0 && count < 9 {
			if count < 3 do first[int(count)] = divisor
			count += 1
		}
	}
	return i64(count == 8 && source_sieve_flag(first[0]) && source_sieve_flag(first[1]) && source_sieve_flag(first[2]))
}
