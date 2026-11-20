package magic_square_doubly_even_complement

FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

hash_byte :: proc(hash: u64, byte: u8) -> u64 {
	return (hash ^ u64(byte)) * FNV_PRIME
}

hash_i32 :: proc(hash: u64, value: i32) -> u64 {
	bits := transmute(u32(value))
	result := hash
	for shift := 0; shift < 32; shift += 8 {
		result = hash_byte(result, u8(bits >> u32(shift)))
	}
	return result
}

@(export)
magic_square_doubly_even_complement :: proc "contextless" (n: i64) -> i64 {
	if n < 4 || n > 64 || n % 4 != 0 do return -1
	order := int(n)
	ceiling := order * order + 1
	hash := hash_byte(FNV_OFFSET, u8(order))

	for row := 0; row < order; row += 1 {
		for column := 0; column < order; column += 1 {
			value := row * order + column + 1
			local_row := row % 4
			local_column := column % 4
			if local_row == local_column || local_row + local_column == 3 {
				value = ceiling - value
			}
			hash = hash_i32(hash, i32(value))
		}
	}
	return i64(hash & 0x7fffffffffffffff)
}
