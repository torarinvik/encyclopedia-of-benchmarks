module bostan_mori_recurrence_term

const max_order = 8
const modulus = i64(998244353)

fn convolve(left []i64, right []i64) []i64 {
	mut product := []i64{len: left.len + right.len - 1}
	for i, first in left {
		for j, second in right {
			at := i + j
			product[at] = (product[at] + first * second) % modulus
		}
	}
	return product
}

@[export: 'bostan_mori_recurrence_term']
pub fn bostan_mori_recurrence_term(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	unsafe {
		order_word := input[0]
		index_word := input[1]
		if order_word < 1 || order_word > max_order || index_word < 0
			|| index_word > 1000000000000000000 { return -1 }
		order := int(order_word)
		if length != usize(2 + 2 * order) { return -1 }

		mut initial := []i64{len: order}
		mut denominator := []i64{len: order + 1}
		mut numerator := []i64{len: order}
		denominator[0] = 1
		for i in 0 .. order {
			coefficient := input[2 + i]
			initial[i] = input[2 + order + i]
			if coefficient < 0 || coefficient >= modulus || initial[i] < 0 || initial[i] >= modulus { return -1 }
			denominator[i + 1] = (modulus - coefficient) % modulus
		}
		first_product := convolve(initial, denominator)
		for i in 0 .. order { numerator[i] = first_product[i] }

		mut index := u64(index_word)
		for index > 0 {
			mut denominator_negative := []i64{len: order + 1}
			for i in 0 .. order + 1 {
				if i % 2 == 0 || denominator[i] == 0 {
					denominator_negative[i] = denominator[i]
				} else {
					denominator_negative[i] = modulus - denominator[i]
				}
			}
			numerator_product := convolve(numerator, denominator_negative)
			denominator_product := convolve(denominator, denominator_negative)
			parity := int(index & 1)
			for i in 0 .. order { numerator[i] = numerator_product[2 * i + parity] }
			for i in 0 .. order + 1 { denominator[i] = denominator_product[2 * i] }
			index >>= 1
		}
		return numerator[0]
	}
}
