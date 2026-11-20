module main

const max_n = i64(22)
const max_parseable_length = usize(2)

fn wn_gcd(a_value i64, b_value i64) i64 {
	mut left := a_value
	mut right := b_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn wn_numerator(n i64) i64 {
	mut numerator := i64(0)
	mut denominator := i64(1)
	mut k := i64(1)
	for k <= n {
		square := k * k
		common := wn_gcd(denominator, square)
		scale := square / common
		numerator = numerator * scale + denominator / common
		denominator *= scale
		factor := wn_gcd(numerator, denominator)
		numerator /= factor
		denominator /= factor
		k++
	}
	return numerator
}

@[export: 'wolstenholme_numbers']
pub fn wolstenholme_numbers(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		if length != 1 { return -1 }
		n := input[0]
		if n < 1 || n > max_n { return -1 }
		return wn_numerator(n)
	}
}
