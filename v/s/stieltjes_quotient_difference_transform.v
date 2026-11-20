module stieltjes_quotient_difference_transform

const modulus = i64(998244353)
const max_words = 11
const table_columns = 9

fn stieltjes_mod(value i64) i64 {
	mut reduced := value % modulus
	if reduced < 0 { reduced += modulus }
	return reduced
}

fn stieltjes_mul(left i64, right i64) i64 { return (left * right) % modulus }

fn stieltjes_power(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = stieltjes_mul(result, base) }
		base = stieltjes_mul(base, base)
		exponent >>= 1
	}
	return result
}

fn stieltjes_store_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> u32(byte * 8)) & 255) }
	}
}

@[export: 'stieltjes_quotient_difference_transform']
pub fn stieltjes_quotient_difference_transform(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_words { return -1 }
	unsafe {
		count_value := input[0]
		if count_value < 2 || count_value > 9 || length != usize(count_value + 1) { return -1 }
		count := int(count_value)
		for i in 0 .. count {
			value := input[i + 1]
			if value <= 0 || value >= modulus { return -1 }
		}

		mut q := [45]i64{}
		mut e := [45]i64{}
		for k in 0 .. count - 1 { q[table_columns + k] = stieltjes_mul(input[k + 2], stieltjes_power(input[k + 1], modulus - 2)) }
		for j in 1 .. 5 {
			last_e := count - 2 * j - 1
			if last_e < 0 { break }
			for k in 0 .. last_e + 1 {
				e[j * table_columns + k] = stieltjes_mod(e[(j - 1) * table_columns + k + 1] + q[j * table_columns + k + 1] - q[j * table_columns + k])
			}
			last_q := count - 2 * j - 2
			if last_q >= 0 {
				for k in 0 .. last_q + 1 {
					pivot := e[j * table_columns + k]
					if pivot == 0 { return -1 }
					product := stieltjes_mul(q[j * table_columns + k + 1], e[j * table_columns + k + 1])
					q[(j + 1) * table_columns + k] = stieltjes_mul(product, stieltjes_power(pivot, modulus - 2))
				}
			}
		}

		required := 8 * (count + 1)
		if output == nil || capacity < required { return -2 }
		stieltjes_store_i64(mut output, 0, count_value)
		for index in 1 .. count {
			value := if index % 2 == 1 { q[((index + 1) / 2) * table_columns] } else { e[(index / 2) * table_columns] }
			stieltjes_store_i64(mut output, 8 * index, value)
		}
		return i64(required)
	}
}
