package bitwise_or_convolution

MAX_N :: 8
MAX_SIZE :: 256
MAX_INPUT :: 513
MODULUS :: i64(998244353)

store_i64_le :: proc(out: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { out[offset+byte] = u8((bits >> (8*byte)) & 255) }
}

bitwise_or_convolution :: proc "c"(input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT do return -1
	nv := input[0]
	if nv < 0 || nv > MAX_N do return -1
	n := int(nv); size := 1 << n
	if length != c.size_t(1+2*size) do return -1
	for i := 0; i < 2*size; i += 1 { if input[1+i] < 0 || input[1+i] >= MODULUS do return -1 }
	bytes := 8*size
	if output == nil || capacity < c.size_t(bytes) do return -2
	a, b: [MAX_SIZE]i64 = {}, {}
	for i := 0; i < size; i += 1 { a[i] = input[1+i]; b[i] = input[1+size+i] }
	for bit := 0; bit < n; bit += 1 {
		bit_mask := 1 << bit
		for mask := 0; mask < size; mask += 1 { if (mask & bit_mask) != 0 {
			a[mask] = (a[mask]+a[mask ^ bit_mask]) % MODULUS
			b[mask] = (b[mask]+b[mask ^ bit_mask]) % MODULUS
		} }
	}
	for i := 0; i < size; i += 1 { a[i] = (a[i]*b[i]) % MODULUS }
	for bit := 0; bit < n; bit += 1 {
		bit_mask := 1 << bit
		for mask := 0; mask < size; mask += 1 { if (mask & bit_mask) != 0 {
			a[mask] -= a[mask ^ bit_mask]
			if a[mask] < 0 { a[mask] += MODULUS }
		} }
	}
	for i := 0; i < size; i += 1 { store_i64_le(output, 8*i, a[i]) }
	return i64(bytes)
}
