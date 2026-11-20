const fnv_offset = u64(0xcbf29ce484222325)
const fnv_prime = u64(0x100000001b3)

fn magic_square_doubly_even_hash_byte(hash u64, byte u8) u64 {
	return (hash ^ u64(byte)) * fnv_prime
}

fn magic_square_doubly_even_hash_i32(mut hash u64, value int) u64 {
	bits := u32(i32(value))
	for shift in 0 .. 4 {
		hash = magic_square_doubly_even_hash_byte(hash, u8(bits >> (shift * 8)))
	}
	return hash
}

@[export: 'magic_square_doubly_even_complement']
pub fn magic_square_doubly_even_complement(n i64) i64 {
	if n < 4 || n > 64 || n % 4 != 0 { return -1 }
	order := int(n)
	ceiling := order * order + 1
	mut hash := magic_square_doubly_even_hash_byte(fnv_offset, u8(order))

	for row in 0 .. order {
		for column in 0 .. order {
			mut value := row * order + column + 1
			local_row := row % 4
			local_column := column % 4
			if local_row == local_column || local_row + local_column == 3 {
				value = ceiling - value
			}
			hash = magic_square_doubly_even_hash_i32(hash, value)
		}
	}
	return i64(hash & u64(0x7fffffffffffffff))
}
