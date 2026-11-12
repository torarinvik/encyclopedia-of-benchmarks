package multipoint_evaluation

import "core:c"

MODULUS :: i64(998244353)
MAX_N :: 8
MAX_M :: 8
LEAF_BASE :: 8
NODE_CAPACITY :: 16
COEFFICIENT_CAPACITY :: 9
MAX_INPUT :: 18
Polynomial :: [COEFFICIENT_CAPACITY]i64
Product_Tree :: [NODE_CAPACITY]Polynomial
Node_Values :: [NODE_CAPACITY]int

store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

trim :: proc(polynomial: ^Polynomial, initial_length: int) -> int {
	length := initial_length
	for length > 1 && polynomial^[length - 1] == 0 { length -= 1 }
	return length
}

multiply :: proc(left, right: ^Polynomial, left_length, right_length: int, product: ^Polynomial) -> int {
	length := left_length + right_length - 1
	for i := 0; i < length; i += 1 { product^[i] = 0 }
	for i := 0; i < left_length; i += 1 {
		for j := 0; j < right_length; j += 1 {
			product^[i + j] = (product^[i + j] + left^[i] * right^[j]) % MODULUS
		}
	}
	return length
}

poly_remainder :: proc(dividend, divisor: ^Polynomial, dividend_length, divisor_length: int, result: ^Polynomial) -> int {
	for i := 0; i < COEFFICIENT_CAPACITY; i += 1 { result^[i] = 0 }
	if divisor_length == 1 && divisor^[0] == 1 do return 1
	for i := 0; i < dividend_length; i += 1 { result^[i] = dividend^[i] }
	length := trim(result, dividend_length)
	for length >= divisor_length {
		shift := length - divisor_length
		factor := result^[length - 1]
		for degree := 0; degree < divisor_length; degree += 1 {
			slot := shift + degree
			result^[slot] = (result^[slot] - factor * divisor^[degree]) % MODULUS
			if result^[slot] < 0 { result^[slot] += MODULUS }
		}
		length = trim(result, length)
	}
	return length
}

@(export)
multipoint_evaluation :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_M do return -1
	n := int(input[0])
	m := int(input[1])
	if int(length) != 2 + n + m do return -1
	for i := 0; i < n + m; i += 1 {
		if input[2 + i] < 0 || input[2 + i] >= MODULUS do return -1
	}
	if input[1 + n] == 0 do return -1
	bytes := 8 * m
	if output == nil || int(capacity) < bytes do return -2

	products: Product_Tree
	remainders: Product_Tree
	product_lengths: Node_Values
	remainder_lengths: Node_Values
	starts: Node_Values
	spans: Node_Values
	for node := 1; node < NODE_CAPACITY; node += 1 {
		products[node][0] = 1
		product_lengths[node] = 1
	}
	for i := 0; i < m; i += 1 {
		leaf := LEAF_BASE + i
		point := input[2 + n + i]
		products[leaf][0] = i64(0)
		if point != 0 { products[leaf][0] = MODULUS - point }
		products[leaf][1] = 1
		product_lengths[leaf] = 2
	}
	for node := LEAF_BASE - 1; node > 0; node -= 1 {
		product_lengths[node] = multiply(&products[2 * node], &products[2 * node + 1],
			product_lengths[2 * node], product_lengths[2 * node + 1], &products[node])
	}
	starts[1] = 0
	spans[1] = LEAF_BASE
	for node := 1; node < LEAF_BASE; node += 1 {
		spans[2 * node] = spans[node] / 2
		spans[2 * node + 1] = spans[node] / 2
		starts[2 * node] = starts[node]
		starts[2 * node + 1] = starts[node] + spans[node] / 2
	}
	var input_polynomial: Polynomial
	for i := 0; i < n; i += 1 { input_polynomial[i] = input[2 + i] }
	remainder_lengths[1] = poly_remainder(&input_polynomial, &products[1], n, product_lengths[1], &remainders[1])
	for node := 1; node < LEAF_BASE; node += 1 {
		for side := 0; side < 2; side += 1 {
			child := 2 * node + side
			if starts[child] < m {
				remainder_lengths[child] = poly_remainder(&remainders[node], &products[child],
					remainder_lengths[node], product_lengths[child], &remainders[child])
			}
		}
	}
	for i := 0; i < m; i += 1 { store_le(output, 8 * i, remainders[LEAF_BASE + i][0]) }
	return i64(bytes)
}
