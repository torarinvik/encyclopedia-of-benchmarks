package wolstenholme_numbers

import "core:c"

MAX_N :: i64(22)
MAX_PARSEABLE_LENGTH :: 2

wn_gcd :: proc "contextless" (a_value, b_value: i64) -> i64 {
	left := a_value
	right := b_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

wn_numerator :: proc "contextless" (n: i64) -> i64 {
	top := i64(0)
	bottom := i64(1)
	for k := i64(1); k <= n; k += 1 {
		square := k * k
		common := wn_gcd(bottom, square)
		scale := square / common
		top = top * scale + bottom / common
		bottom *= scale
		factor := wn_gcd(top, bottom)
		top /= factor
		bottom /= factor
	}
	return top
}

@(export)
wolstenholme_numbers :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	if length != 1 || input[0] < 1 || input[0] > MAX_N do return -1
	return wn_numerator(input[0])
}
