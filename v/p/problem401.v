module problem401

const max_limit = i64(1000)
const mod_limit = i64(1000000000)

fn contains(value i64, divisors []i64, length int) bool {
	for i in 0 .. length { if divisors[i] == value { return true } }
	return false
}
fn get_divisors(number i64, mut divisors []i64) int {
	if number == 1 { divisors[0] = 1; return 1 }
	mut count := 0
	mut divisor := i64(1)
	for divisor * divisor <= number + 1 {
		if number % divisor == 0 {
			quotient := number / divisor
			if !contains(divisor, divisors, count) { divisors[count] = divisor; count++ }
			if !contains(quotient, divisors, count) { divisors[count] = quotient; count++ }
		}
		divisor++
	}
	return count
}
fn sigma2_source(number i64) i64 {
	mut divisors := []i64{len: 128, init: 0}
	count := get_divisors(number, mut divisors)
	mut sum := i64(0)
	for i in 1 .. count { sum += (divisors[i] * divisors[i]) % mod_limit }
	return sum % mod_limit
}

@[export: 'problem401']
pub fn problem401(limit i64) i64 {
	if limit < 0 || limit > max_limit { return -1 }
	mut sum := i64(0)
	for number := i64(0); number <= limit; number++ { sum += sigma2_source(number) }
	return sum % mod_limit
}
