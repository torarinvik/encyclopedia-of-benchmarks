module five11

fn read_bits(values &i64, length usize, bit_offset usize, width usize) i64 {
	bit_length := length * 8
	if bit_offset > bit_length || width > bit_length - bit_offset { return -1 }
	byte_offset := bit_offset >> 3
	start := bit_offset & 7
	byte_count := (start + width + 7) >> 3
	mut window := u32(0)
	unsafe {
		for index in 0 .. byte_count {
			window = (window << 8) | u32(values[byte_offset + index])
		}
	}
	shift := byte_count * 8 - start - width
	mask := (u32(1) << u32(width)) - 1
	return i64((window >> u32(shift)) & mask)
}

fn decode_sum(values &i64, length usize) i64 {
	packet_count := read_bits(values, length, 0, 16)
	if packet_count < 0 || packet_count > 451 { return -1 }
	mut bit_offset := usize(16)
	mut total := i64(0)
	for _ in 0 .. int(packet_count) {
		channels := read_bits(values, length, bit_offset, 5)
		if channels < 0 { return -1 }
		bit_offset += 5
		for _ in 0 .. int(channels) {
			value := read_bits(values, length, bit_offset, 11)
			if value < 0 { return -1 }
			total += value
			bit_offset += 11
		}
		packet_bits := 5 + 11 * int(channels)
		bit_offset += usize((8 - (packet_bits & 7)) & 7)
		if bit_offset > length * 8 { return -1 }
	}
	return total
}

@[export: 'five11']
pub fn five11(values &i64, length usize) i64 {
	if values == nil || length < 2 || length > 13524 || length > 13523 { return -1 }
	unsafe {
		for index in 0 .. length {
			if values[index] < 0 || values[index] > 255 { return -1 }
		}
	}
	mut result := i64(0)
	for _ in 0 .. 10000 {
		result = decode_sum(values, length)
		if result < 0 { return -1 }
	}
	return result
}
