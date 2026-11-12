package mul_mod2n_convolution
import "core:c"

MAX_N :: 5
MAX_P :: 32
MAX_INPUT :: 66
MAX_OUTPUT :: 256
MOD :: i64(998244353)

store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
mul_mod2n_convolution :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	n0 := input[0]
	if n0 < 0 || n0 > MAX_N do return -1
	p := 1 << int(n0)
	if length != c.size_t(1 + 2*p) do return -1
	for i := 1; i < int(length); i += 1 { if input[i] < 0 || input[i] >= MOD do return -1 }
	bytes := 8*p
	if bytes > MAX_OUTPUT do return -1
	if output == nil || capacity < c.size_t(bytes) do return -2
	a, b, result: [MAX_P]i64 = {}, {}, {}
	for i := 0; i < p; i += 1 { a[i] = input[1+i]; b[i] = input[1+p+i] }
	mask := p-1
	for i := 0; i < p; i += 1 { for j := 0; j < p; j += 1 {
		k := (i*j) & mask
		result[k] = (result[k] + a[i]*b[j]) % MOD
	} }
	for i := 0; i < p; i += 1 { store_le(output,8*i,result[i]) }
	return i64(bytes)
}
