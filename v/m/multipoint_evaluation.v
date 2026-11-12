module multipoint_evaluation

const modulus = i64(998244353)
const max_n = 8
const max_m = 8
const leaf_base = 8
const node_capacity = 16
const coefficient_capacity = 9
const max_input = 18

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn trim(poly []i64, offset int, initial_length int) int {
	mut length := initial_length
	for length > 1 && poly[offset + length - 1] == 0 { length-- }
	return length
}

fn multiply(left []i64, left_offset int, left_length int, right []i64, right_offset int,
	right_length int, mut product []i64, product_offset int) int {
	length := left_length + right_length - 1
	for i in 0 .. length { product[product_offset + i] = 0 }
	for i in 0 .. left_length {
		for j in 0 .. right_length {
			product[product_offset + i + j] = (product[product_offset + i + j] +
				left[left_offset + i] * right[right_offset + j]) % modulus
		}
	}
	return length
}

fn poly_remainder(dividend []i64, dividend_offset int, dividend_length int,
	divisor []i64, divisor_offset int, divisor_length int,
	mut result []i64, result_offset int) int {
	if divisor_length == 1 && divisor[divisor_offset] == 1 {
		result[result_offset] = 0
		return 1
	}
	for i in 0 .. dividend_length { result[result_offset + i] = dividend[dividend_offset + i] }
	mut length := trim(result, result_offset, dividend_length)
	for length >= divisor_length {
		shift := length - divisor_length
		factor := result[result_offset + length - 1]
		for degree in 0 .. divisor_length {
			slot := result_offset + shift + degree
			result[slot] = (result[slot] - factor * divisor[divisor_offset + degree]) % modulus
			if result[slot] < 0 { result[slot] += modulus }
		}
		length = trim(result, result_offset, length)
	}
	return length
}

@[export: 'multipoint_evaluation']
pub fn multipoint_evaluation(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		if input[0] < 1 || input[0] > max_n || input[1] < 1 || input[1] > max_m { return -1 }
		n := int(input[0])
		m := int(input[1])
		if length != usize(2 + n + m) { return -1 }
		for i in 0 .. n + m {
			if input[2 + i] < 0 || input[2 + i] >= modulus { return -1 }
		}
		if input[1 + n] == 0 { return -1 }
		bytes := 8 * m
		if output == nil || capacity < usize(bytes) { return -2 }

		mut products := [node_capacity * coefficient_capacity]i64{}
		mut remainders := [node_capacity * coefficient_capacity]i64{}
		mut product_lengths := [node_capacity]int{}
		mut remainder_lengths := [node_capacity]int{}
		mut starts := [node_capacity]int{}
		mut spans := [node_capacity]int{}
		for node in 1 .. node_capacity {
			products[node * coefficient_capacity] = 1
			product_lengths[node] = 1
		}
		for i in 0 .. m {
			leaf := leaf_base + i
			point := input[2 + n + i]
			products[leaf * coefficient_capacity] = if point == 0 { i64(0) } else { modulus - point }
			products[leaf * coefficient_capacity + 1] = 1
			product_lengths[leaf] = 2
		}
		for node := leaf_base - 1; node > 0; node-- {
			product_lengths[node] = multiply(products[..], 2 * node * coefficient_capacity,
				product_lengths[2 * node], products[..], (2 * node + 1) * coefficient_capacity,
				product_lengths[2 * node + 1], mut products[..], node * coefficient_capacity)
		}
		starts[1] = 0
		spans[1] = leaf_base
		for node in 1 .. leaf_base {
			spans[2 * node] = spans[node] / 2
			spans[2 * node + 1] = spans[node] / 2
			starts[2 * node] = starts[node]
			starts[2 * node + 1] = starts[node] + spans[node] / 2
		}
		mut input_poly := [coefficient_capacity]i64{}
		for i in 0 .. n { input_poly[i] = input[2 + i] }
		remainder_lengths[1] = poly_remainder(input_poly[..], 0, n, products[..], coefficient_capacity,
			product_lengths[1], mut remainders[..], coefficient_capacity)
		for node in 1 .. leaf_base {
			for side in 0 .. 2 {
				child := 2 * node + side
				if starts[child] < m {
				remainder_lengths[child] = poly_remainder(remainders[..], node * coefficient_capacity,
					remainder_lengths[node], products[..], child * coefficient_capacity,
					product_lengths[child], mut remainders[..], child * coefficient_capacity)
				}
			}
		}
		for i in 0 .. m { store_le(mut output, 8 * i, remainders[(leaf_base + i) * coefficient_capacity]) }
		return i64(bytes)
	}
}
