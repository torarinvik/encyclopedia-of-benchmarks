package spatial_motif_different_type_contact_pmf

import "core:c"

MAX_LENGTH :: 10
MAX_SUPPORT :: 11

choose_value :: proc "contextless" (total, selected0: int) -> i64 {
	if total < 0 || selected0 < 0 || selected0 > total do return 0
	selected := selected0
	if selected > total-selected { selected = total-selected }
	result: i64 = 1
	for factor := 1; factor <= selected; factor += 1 {
		result = result * i64(total-selected+factor) / i64(factor)
	}
	return result
}

multinomial3 :: proc "contextless" (total, first, second: int) -> i64 {
	if total < 0 || first < 0 || second < 0 || first > total || second > total ||
		first+second > total do return 0
	return choose_value(total, first) * choose_value(total-first, second)
}

gcd_value :: proc "contextless" (left0, right0: i64) -> i64 {
	left, right := left0, right0
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

put_i64 :: proc "contextless" (output: [^]u8, word: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[word*8+byte] = u8((bits >> (byte*8)) & 255)
	}
}

@(export)
spatial_motif_different_type_contact_pmf :: proc "c" (input: [^]i64, input_length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length != 5 do return -1
	n0, x10, y10, x20, y20 := input[0], input[1], input[2], input[3], input[4]
	if n0 < 1 || n0 > MAX_LENGTH || x10 < 0 || y10 < 0 || x20 < 0 || y20 < 0 ||
		x10 > n0 || y10 > n0 || x20 > n0 || y20 > n0 do return -1
	if x10+y10 > n0 || x20+y20 > n0 do return -1

	n, x1, y1, x2, y2 := int(n0), int(x10), int(y10), int(x20), int(y20)
	neither1 := n-x1-y1
	denominator := multinomial3(n, x2, y2)
	numerators: [MAX_SUPPORT]i64
	for index := 0; index < MAX_SUPPORT; index += 1 { numerators[index] = 0 }
	for m := 0; m <= n; m += 1 {
		for xx := 0; xx <= x1; xx += 1 {
			for xy := 0; xy <= x1-xx; xy += 1 {
				yx := m-xy
				if yx < 0 || yx > y1 do continue
				for yy := 0; yy <= y1-yx; yy += 1 {
					numerators[m] += multinomial3(x1, xx, xy) *
						multinomial3(y1, yx, yy) *
						multinomial3(neither1, x2-xx-yx, y2-xy-yy)
				}
			}
		}
	}

	expected_numerator: i64 = 0
	for m := 0; m <= n; m += 1 { expected_numerator += i64(m)*numerators[m] }
	expected_denominator := denominator
	divisor := gcd_value(expected_numerator, expected_denominator)
	expected_numerator /= divisor
	expected_denominator /= divisor
	bytes := c.size_t((n+5)*8)
	if output == nil || output_capacity < bytes do return -2
	put_i64(output, 0, i64(n)); put_i64(output, 1, denominator)
	for m := 0; m <= n; m += 1 { put_i64(output, m+2, numerators[m]) }
	put_i64(output, n+3, expected_numerator); put_i64(output, n+4, expected_denominator)
	return i64(bytes)
}
