module binomial_calculate

const InvalidResult = i64(-1)

@[export: 'binomial_calculate']
pub fn binomial_calculate(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 2 { return InvalidResult }
	n, mut k := input[0], input[1]
	if n < 0 || n > 62 || k < 0 || k > n { return InvalidResult }
	if k > n / 2 { k = n - k }
	mut result := u64(1)
	for i := i64(1); i <= k; i++ {
		result *= u64(n - k + i)
		result /= u64(i)
	}
	return i64(result)
}
