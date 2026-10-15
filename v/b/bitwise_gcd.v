module bitwise_gcd

fn trailing_zeros(value u64) int {
	mut current := value
	mut count := 0
	for (current & u64(1)) == 0 {
		current >>= 1
		count++
	}
	return count
}

@[export: 'bitwise_gcd']
pub fn bitwise_gcd(left u64, right u64) i64 {
	if left == 0 { return i64(right) }
	if right == 0 { return i64(left) }

	common_twos := trailing_zeros(left | right)
	mut a := left >> trailing_zeros(left)
	mut b := right
	for b != 0 {
		b >>= trailing_zeros(b)
		if a > b {
			temp := a
			a = b
			b = temp
		}
		b -= a
	}
	return i64(a << common_twos)
}
