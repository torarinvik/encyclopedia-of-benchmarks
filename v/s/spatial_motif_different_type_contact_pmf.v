module spatial_motif_different_type_contact_pmf

const max_length = 10
const max_support = 11

fn choose_value(total int, selected0 int) i64 {
	if total < 0 || selected0 < 0 || selected0 > total { return 0 }
	mut selected := selected0
	if selected > total-selected { selected = total-selected }
	mut value := i64(1)
	for factor := 1; factor <= selected; factor++ {
		value = value * i64(total-selected+factor) / i64(factor)
	}
	return value
}

fn multinomial3(total int, first int, second int) i64 {
	if total < 0 || first < 0 || second < 0 || first > total || second > total ||
		first+second > total { return 0 }
	return choose_value(total, first) * choose_value(total-first, second)
}

fn gcd_value(left0 i64, right0 i64) i64 {
	mut left := left0
	mut right := right0
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn put_i64_le(mut output &u8, word int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[word*8+byte] = u8((bits >> (byte*8)) & 255) } }
}

@[export: 'spatial_motif_different_type_contact_pmf']
pub fn spatial_motif_different_type_contact_pmf(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if input == nil || length != 5 { return -1 }
	n0 := unsafe { input[0] }; x10 := unsafe { input[1] }; y10 := unsafe { input[2] }
	x20 := unsafe { input[3] }; y20 := unsafe { input[4] }
	if n0 < 1 || n0 > max_length || x10 < 0 || y10 < 0 || x20 < 0 || y20 < 0 ||
		x10 > n0 || y10 > n0 || x20 > n0 || y20 > n0 { return -1 }
	if x10+y10 > n0 || x20+y20 > n0 { return -1 }

	n := int(n0); x1 := int(x10); y1 := int(y10); x2 := int(x20); y2 := int(y20)
	neither1 := n-x1-y1
	denominator := multinomial3(n, x2, y2)
	mut numerators := [max_support]i64{}
	for m in 0 .. n+1 {
		for xx in 0 .. x1+1 {
			for xy in 0 .. x1-xx+1 {
				yx := m-xy
				if yx < 0 || yx > y1 { continue }
				for yy in 0 .. y1-yx+1 {
					numerators[m] += multinomial3(x1, xx, xy) *
						multinomial3(y1, yx, yy) *
						multinomial3(neither1, x2-xx-yx, y2-xy-yy)
				}
			}
		}
	}

	mut expected_numerator := i64(0)
	for m in 0 .. n+1 { expected_numerator += i64(m)*numerators[m] }
	mut expected_denominator := denominator
	divisor := gcd_value(expected_numerator, expected_denominator)
	expected_numerator /= divisor; expected_denominator /= divisor
	bytes := (n+5)*8
	if output == nil || capacity < usize(bytes) { return -2 }
	put_i64_le(mut output, 0, i64(n)); put_i64_le(mut output, 1, denominator)
	for m in 0 .. n+1 { put_i64_le(mut output, m+2, numerators[m]) }
	put_i64_le(mut output, n+3, expected_numerator)
	put_i64_le(mut output, n+4, expected_denominator)
	return i64(bytes)
}
