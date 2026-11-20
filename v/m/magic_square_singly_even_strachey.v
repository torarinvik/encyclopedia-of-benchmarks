const max_order = 30
const fnv_offset = u64(0xcbf29ce484222325)
const fnv_prime = u64(0x100000001b3)

fn hash_byte(hash u64, byte u8) u64 {
	return (hash ^ u64(byte)) * fnv_prime
}

fn hash_i32(mut hash u64, value int) u64 {
	bits := u32(i32(value))
	for shift in 0 .. 4 { hash = hash_byte(hash, u8(bits >> (shift * 8))) }
	return hash
}

@[export: 'magic_square_singly_even_strachey']
pub fn magic_square_singly_even_strachey(n i64) i64 {
	if n < 6 || n > max_order || n % 4 != 2 { return -1 }
	order := int(n)
	half := order / 2
	k := half / 2
	block_size := half * half
	mut odd := [900]int{}
	mut square := [900]int{}

	mut row := 0
	mut column := half / 2
	odd[row * 30 + column] = 1
	for value := 2; value <= block_size; value++ {
		next_row := (row - 1 + half) % half
		next_column := (column + 1) % half
		if odd[next_row * 30 + next_column] == 0 {
			row = next_row
			column = next_column
		} else {
			row = (row + 1) % half
		}
		odd[row * 30 + column] = value
	}

	for r in 0 .. half {
		for c in 0 .. half {
			value := odd[r * 30 + c]
			square[r * 30 + c] = value
			square[r * 30 + half + c] = value + 2 * block_size
			square[(half + r) * 30 + c] = value + 3 * block_size
			square[(half + r) * 30 + half + c] = value + block_size
		}
	}

	for r in 0 .. half {
		for c in 0 .. k {
			top := r * 30 + c
			bottom := (half + r) * 30 + c
			saved := square[top]; square[top] = square[bottom]; square[bottom] = saved
		}
		for c := half - (k - 1); c < half; c++ {
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

	mut hash := hash_byte(fnv_offset, u8(order))
	for r in 0 .. order {
		for c in 0 .. order { hash = hash_i32(hash, square[r * 30 + c]) }
	}
	return i64(hash & u64(0x7fffffffffffffff))
}
