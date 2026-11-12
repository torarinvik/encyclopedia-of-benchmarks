package bostan_mori_recurrence_term

import "core:c"

MAX_ORDER :: 8
MODULUS :: i64(998244353)
Polynomial :: [MAX_ORDER + 1]i64
Product :: [2 * MAX_ORDER + 1]i64

convolve :: proc(left: Polynomial, left_len: int, right: Polynomial, right_len: int) -> Product {
	product: Product
	for i := 0; i < left_len + right_len - 1; i += 1 {
		product[i] = 0
	}
	for i := 0; i < left_len; i += 1 {
		for j := 0; j < right_len; j += 1 {
			at := i + j
			product[at] = (product[at] + left[i] * right[j]) % MODULUS
		}
	}
	return product
}

@(export)
bostan_mori_recurrence_term :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 do return -1
	order_word, index_word := input[0], input[1]
	if order_word < 1 || order_word > MAX_ORDER || index_word < 0 || index_word > 1000000000000000000 do return -1
	order := int(order_word)
	if length != c.size_t(2 + 2 * order) do return -1

	var numerator, initial, denominator: Polynomial
	denominator[0] = 1
	for i := 0; i < order; i += 1 {
		coefficient := input[2 + i]
		initial[i] = input[2 + order + i]
		if coefficient < 0 || coefficient >= MODULUS || initial[i] < 0 || initial[i] >= MODULUS do return -1
		denominator[i + 1] = (MODULUS - coefficient) % MODULUS
	}
	first_product := convolve(initial, order, denominator, order + 1)
	for i := 0; i < order; i += 1 { numerator[i] = first_product[i] }

	index := u64(index_word)
	for index > 0 {
		var denominator_negative: Polynomial
		for i := 0; i <= order; i += 1 {
			if i % 2 == 0 || denominator[i] == 0 {
				denominator_negative[i] = denominator[i]
			} else {
				denominator_negative[i] = MODULUS - denominator[i]
			}
		}
		numerator_product := convolve(numerator, order, denominator_negative, order + 1)
		denominator_product := convolve(denominator, order + 1, denominator_negative, order + 1)
		parity := int(index & 1)
		for i := 0; i < order; i += 1 { numerator[i] = numerator_product[2 * i + parity] }
		for i := 0; i <= order; i += 1 { denominator[i] = denominator_product[2 * i] }
		index >>= 1
	}
	return numerator[0]
}
