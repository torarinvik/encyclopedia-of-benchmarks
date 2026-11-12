module product_of_polynomial_sequence

const modulus = i64(998_244_353)
const max_factors = 6
const max_coefficients = 25
const max_input = 38

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'product_of_polynomial_sequence']
pub fn product_of_polynomial_sequence(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input { return -1 }
		if input[0] < 0 || input[0] > max_factors { return -1 }
		count := int(input[0])
		mut polynomials := [max_factors * max_coefficients]i64{}
		mut lengths := [max_factors]int{}
		mut cursor := 1
		mut degree_sum := 0
		for p in 0 .. count {
			if cursor >= int(length) || input[cursor] < 0 || input[cursor] > 4 { return -1 }
			degree := int(input[cursor])
			cursor++
			if cursor + degree + 1 > int(length) { return -1 }
			for i in 0 .. degree + 1 {
				coefficient := input[cursor + i]
				if coefficient < 0 || coefficient >= modulus { return -1 }
				polynomials[p * max_coefficients + i] = coefficient
			}
			if polynomials[p * max_coefficients + degree] == 0 { return -1 }
			lengths[p] = degree + 1
			degree_sum += degree
			cursor += degree + 1
		}
		if cursor != int(length) { return -1 }

		result_length := degree_sum + 1
		bytes := 8 * result_length
		if output == nil || capacity < usize(bytes) { return -2 }
		if count == 0 {
			store_le(mut output, 0, 1)
			return 8
		}

		mut scratch := [max_coefficients]i64{}
		mut active := count
		for active > 1 {
			mut next_count := 0
			mut i := 0
			for i < active {
				destination := next_count * max_coefficients
				if i + 1 == active {
					source := i * max_coefficients
					for j in 0 .. lengths[i] { polynomials[destination + j] = polynomials[source + j] }
					lengths[next_count] = lengths[i]
				} else {
					left_start := i * max_coefficients
					right_start := (i + 1) * max_coefficients
					product_length := lengths[i] + lengths[i + 1] - 1
					for j in 0 .. product_length { scratch[j] = 0 }
					for a in 0 .. lengths[i] {
						for b in 0 .. lengths[i + 1] {
							slot := a + b
							scratch[slot] = (scratch[slot] + polynomials[left_start + a] * polynomials[right_start + b]) % modulus
						}
					}
					for j in 0 .. product_length { polynomials[destination + j] = scratch[j] }
					lengths[next_count] = product_length
				}
				next_count++
				i += 2
			}
			active = next_count
		}
		for i in 0 .. result_length { store_le(mut output, 8 * i, polynomials[i]) }
		return i64(bytes)
	}
}
