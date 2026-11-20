module minkowski_question_mark_rational

const max_denominator = i64(1_000_000)
const max_cf_sum = i64(60)

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

fn cf_sum(numerator i64, denominator i64) i64 {
	mut n := numerator
	mut d := denominator
	mut total := i64(0)
	for n != 0 {
		quotient := d / n
		if quotient > max_cf_sum - total { return -1 }
		total += quotient
		remainder := d % n
		d = n
		n = remainder
	}
	return total
}

fn alternating_numerator(numerator i64, denominator i64, total i64) i64 {
	mut n := numerator
	mut d := denominator
	mut prefix := i64(0)
	mut index := i64(1)
	mut value := i64(0)
	for n != 0 {
		quotient := d / n
		prefix += quotient
		term := i64(1) << int(total - prefix)
		if index % 2 == 1 { value += term } else { value -= term }
		remainder := d % n
		d = n
		n = remainder
		index++
	}
	return value
}

@[export: 'minkowski_question_mark_rational']
pub fn minkowski_question_mark_rational(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 3 { return -1 }
		if length != 2 { return -1 }
		p := input[0]
		q := input[1]
		if p < 0 || q < 1 || q > max_denominator || p > q { return -1 }
		total := cf_sum(p, q)
		if total < 0 { return -1 }
		if output == nil || capacity < 16 { return -2 }
		value := alternating_numerator(p, q, total)
		exponent := if total == 0 { i64(0) } else { total - 1 }
		store_i64_le(mut output, 0, value)
		store_i64_le(mut output, 8, exponent)
		return 16
	}
}
