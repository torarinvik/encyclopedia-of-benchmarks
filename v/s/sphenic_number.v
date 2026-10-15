module sphenic_number

fn source_sieve_flag(value i64) bool {
	if value < 2 { return true }
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

@[export: 'sphenic_number']
pub fn sphenic_number(value i64) i64 {
	if value < 0 || value > 1000 { return -1 }
	mut first := [3]i64{}
	mut count := i64(0)
	mut divisor := i64(1)
	for divisor <= value {
		if value % divisor == 0 && count < 9 {
			if count < 3 { first[int(count)] = divisor }
			count++
		}
		divisor++
	}
	return if count == 8 && source_sieve_flag(first[0]) && source_sieve_flag(first[1]) && source_sieve_flag(first[2]) { 1 } else { 0 }
}
