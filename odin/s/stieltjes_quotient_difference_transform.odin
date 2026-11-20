package stieltjes_quotient_difference_transform

import "core:c"

MODULUS :: i64(998244353)
MAX_WORDS :: 11
TABLE_COLUMNS :: 9

stieltjes_mod :: proc(value: i64) -> i64 {
	reduced := value % MODULUS
	if reduced < 0 { return reduced + MODULUS }
	return reduced
}

stieltjes_mul :: proc(left, right: i64) -> i64 { return (left * right) % MODULUS }

stieltjes_power :: proc(base_input, exponent_input: i64) -> i64 {
	base, exponent := base_input, exponent_input
	result := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 { result = stieltjes_mul(result, base) }
		base = stieltjes_mul(base, base)
		exponent >>= 1
	}
	return result
}

stieltjes_store_i64 :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0..<8 { output[offset+byte] = u8(bits >> (8*byte)) }
}

@(export)
stieltjes_quotient_difference_transform :: proc "c" (input: [^]i64, input_length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > MAX_WORDS do return -1
	count_value := input[0]
	if count_value < 2 || count_value > 9 || input_length != c.size_t(count_value+1) do return -1
	count := int(count_value)
	for i in 0..<count { value := input[i+1]; if value <= 0 || value >= MODULUS do return -1 }

	q := [45]i64{}
	e := [45]i64{}
	for k in 0..<count-1 { q[TABLE_COLUMNS+k] = stieltjes_mul(input[k+2],stieltjes_power(input[k+1],MODULUS-2)) }
	for j in 1..4 {
		last_e := count-2*j-1
		if last_e < 0 do break
		for k in 0..<last_e+1 { e[j*TABLE_COLUMNS+k] = stieltjes_mod(e[(j-1)*TABLE_COLUMNS+k+1]+q[j*TABLE_COLUMNS+k+1]-q[j*TABLE_COLUMNS+k]) }
		last_q := count-2*j-2
		if last_q >= 0 {
			for k in 0..<last_q+1 {
				pivot := e[j*TABLE_COLUMNS+k]
				if pivot == 0 do return -1
				product := stieltjes_mul(q[j*TABLE_COLUMNS+k+1],e[j*TABLE_COLUMNS+k+1])
				q[(j+1)*TABLE_COLUMNS+k] = stieltjes_mul(product,stieltjes_power(pivot,MODULUS-2))
			}
		}
	}

	required := 8*(count+1)
	if output == nil || output_capacity < c.size_t(required) do return -2
	stieltjes_store_i64(output,0,count_value)
	for index in 1..<count {
		value := if index%2 != 0 { q[((index+1)/2)*TABLE_COLUMNS] } else { e[(index/2)*TABLE_COLUMNS] }
		stieltjes_store_i64(output,8*index,value)
	}
	return i64(required)
}
