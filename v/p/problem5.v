module problem5

fn gcd(left i64, right i64) i64 {
	mut a := left
	mut b := right
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

@[export: 'problem5']
pub fn problem5(limit i64) i64 {
	if limit < 1 || limit > 20 { return -1 }
	mut result := i64(1)
	for value := i64(2); value <= limit; value++ {
		result = (result / gcd(result, value)) * value
	}
	return result
}
