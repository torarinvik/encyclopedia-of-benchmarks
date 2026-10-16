module problem33

fn gcd_i64(left i64, right i64) i64 {
	mut a := left
	mut b := right
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

@[export: 'problem33']
pub fn problem33(digit_len i64) i64 {
	if digit_len < 0 || digit_len > 5 { return -1 }
	mut upper := i64(1)
	for _ in 0 .. digit_len { upper *= 10 }
	mut result := f64(1.0)
	mut denominator := i64(11)
	for numerator := i64(11); numerator < upper; numerator++ {
		for denominator <= 99 {
			if numerator != denominator && numerator % 10 == denominator / 10 && denominator % 10 != 0 &&
				f64(numerator / 10) / f64(denominator % 10) == f64(numerator) / f64(denominator) {
				divisor := gcd_i64(numerator, denominator)
				result *= f64(denominator / divisor) / f64(numerator / divisor)
			}
			denominator++
		}
		denominator = 10
	}
	return i64(result)
}
