const max_order = 31
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

@[export: 'magic_square']
pub fn magic_square(n i64) i64 {
	if n < 1 || n > max_order || n % 2 == 0 { return -1 }
	order := int(n)
	mut square := [31 * 31]int{}
	mut row := order / 2
	mut column := order - 1
	square[row * 31 + column] = 1
	for value := 2; value <= order * order; value++ {
		next_row := (row - 1 + order) % order
		next_column := (column + 1) % order
		if square[next_row * 31 + next_column] == 0 {
			row = next_row
			column = next_column
		} else {
			column = (column - 1 + order) % order
		}
		square[row * 31 + column] = value
	}
	mut hash := hash_byte(fnv_offset, u8(order))
	for r in 0 .. order {
		for c in 0 .. order { hash = hash_i32(hash, square[r * 31 + c]) }
	}
	return i64(hash & u64(0x7fffffffffffffff))
}
