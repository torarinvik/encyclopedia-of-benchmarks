package shewchuk_expansion_sum

import "core:c"

MAX_TERMS :: 16
MAX_LENGTH :: 34
MAX_MANTISSA :: i64(16777216)
OUTPUT_SCALE :: f64(1073741824.0)

Sum_Pair :: struct { high, low: f64 }

two_sum :: proc "contextless" (a, b: f64) -> Sum_Pair {
	rounded := a+b
	b_virtual := rounded-a
	a_virtual := rounded-b_virtual
	b_roundoff := b-b_virtual
	a_roundoff := a-a_virtual
	return Sum_Pair{rounded,a_roundoff+b_roundoff}
}

grow_expansion :: proc "contextless" (expansion, grown: []f64, count: int, value: f64) -> int {
	q := value
	grown_count := 0
	for i := 0; i < count; i += 1 {
		pair := two_sum(q,expansion[i])
		if pair.low != 0.0 {
			grown[grown_count] = pair.low
			grown_count += 1
		}
		q = pair.high
	}
	if q != 0.0 || grown_count == 0 {
		grown[grown_count] = q
		grown_count += 1
	}
	return grown_count
}

@(export)
shewchuk_expansion_sum :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_LENGTH) do return -1
	if input[0] < 0 || input[0] > MAX_TERMS do return -1
	n := int(input[0])
	if length != c.size_t(1+2*n) do return -1

	var expansion: [MAX_TERMS+1]f64
	var grown: [MAX_TERMS+1]f64
	expansion_count := 0
	for i := 0; i < n; i += 1 {
		mantissa := input[1+2*i]
		exponent := input[2+2*i]
		if mantissa < -MAX_MANTISSA || mantissa > MAX_MANTISSA || exponent < -30 || exponent > 0 do return -1
		value := f64(mantissa)
		for shift: i64 = 0; shift > exponent; shift -= 1 { value *= 0.5 }
		if value != 0.0 {
			grown_count := grow_expansion(expansion[:],grown[:],expansion_count,value)
			for j := 0; j < grown_count; j += 1 { expansion[j] = grown[j] }
			expansion_count = grown_count
		}
	}
	result := (i64(1) << 58)+1
	for i := 0; i < expansion_count; i += 1 { result += i64(expansion[i]*OUTPUT_SCALE) }
	return result
}
