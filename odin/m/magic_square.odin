package magic_square

FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

hash_byte :: proc(hash: u64, byte: u8) -> u64 {
	return (hash ^ u64(byte)) * FNV_PRIME
}

hash_i32 :: proc(hash: u64, value: i32) -> u64 {
	bits := transmute(u32(value))
	result := hash
	for shift := 0; shift < 32; shift += 8 { result = hash_byte(result, u8(bits >> u32(shift))) }
	return result
}

@(export)
magic_square :: proc "contextless" (n: i64) -> i64 {
	if n < 1 || n > 31 || n % 2 == 0 do return -1
	order := int(n)
	var square: [961]i32
	row, column := order / 2, order - 1
	square[row * 31 + column] = 1
	for value := 2; value <= order * order; value += 1 {
		next_row := (row - 1 + order) % order
		next_column := (column + 1) % order
		if square[next_row * 31 + next_column] == 0 {
			row, column = next_row, next_column
		} else {
			column = (column - 1 + order) % order
		}
		square[row * 31 + column] = i32(value)
	}
	hash := hash_byte(FNV_OFFSET, u8(order))
	for r := 0; r < order; r += 1 {
		for c := 0; c < order; c += 1 { hash = hash_i32(hash, square[r * 31 + c]) }
	}
	return i64(hash & 0x7fffffffffffffff)
}
