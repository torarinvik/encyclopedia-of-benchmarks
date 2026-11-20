package magic_square_singly_even_strachey

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
magic_square_singly_even_strachey :: proc "contextless" (n: i64) -> i64 {
	if n < 6 || n > 30 || n % 4 != 2 do return -1
	order := int(n)
	half := order / 2
	k := half / 2
	block_size := half * half
	var odd: [900]i32
	var square: [900]i32

	row, column := 0, half / 2
	odd[row * 30 + column] = 1
	for value := 2; value <= block_size; value += 1 {
		next_row := (row - 1 + half) % half
		next_column := (column + 1) % half
		if odd[next_row * 30 + next_column] == 0 {
			row, column = next_row, next_column
		} else {
			row = (row + 1) % half
		}
		odd[row * 30 + column] = i32(value)
	}

	for r := 0; r < half; r += 1 {
		for c := 0; c < half; c += 1 {
			value := odd[r * 30 + c]
			square[r * 30 + c] = value
			square[r * 30 + half + c] = value + i32(2 * block_size)
			square[(half + r) * 30 + c] = value + i32(3 * block_size)
			square[(half + r) * 30 + half + c] = value + i32(block_size)
		}
	}

	for r := 0; r < half; r += 1 {
		for c := 0; c < k; c += 1 {
			top := r * 30 + c
			bottom := (half + r) * 30 + c
			saved := square[top]; square[top] = square[bottom]; square[bottom] = saved
		}
		for c := half - (k - 1); c < half; c += 1 {
			top := r * 30 + half + c
			bottom := (half + r) * 30 + half + c
			saved := square[top]; square[top] = square[bottom]; square[bottom] = saved
		}
	}
	{
		top := k * 30
		bottom := (half + k) * 30
		saved := square[top]; square[top] = square[bottom]; square[bottom] = saved
	}
	{
		top := k * 30 + k
		bottom := (half + k) * 30 + k
		saved := square[top]; square[top] = square[bottom]; square[bottom] = saved
	}

	hash := hash_byte(FNV_OFFSET, u8(order))
	for r := 0; r < order; r += 1 {
		for c := 0; c < order; c += 1 { hash = hash_i32(hash, square[r * 30 + c]) }
	}
	return i64(hash & 0x7fffffffffffffff)
}
