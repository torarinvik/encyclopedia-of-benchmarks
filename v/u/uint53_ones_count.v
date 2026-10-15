module uint53_ones_count

const max_uint53 = i64(9007199254740991)

fn count_byte_ones(byte i64) i64 {
	mut current := byte
	mut ones := i64(0)
	for current > 0 {
		bit := current % 2
		ones += bit
		current = (current - bit) / 2
	}
	return ones
}

// Count set bits in the bounded unsigned 53-bit domain, byte by byte.
@[export: 'uint53_ones_count']
pub fn uint53_ones_count(n i64) i64 {
	if n < 0 || n > max_uint53 { return -1 }

	mut current := n
	mut ones := i64(0)
	for current != 0 {
		byte := current % 256
		ones += count_byte_ones(byte)
		current = (current - byte) / 256
	}
	return ones
}
