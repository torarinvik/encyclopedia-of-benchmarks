module sdes

const p8 = [8]u8{6, 3, 7, 4, 8, 5, 10, 9}
const p10 = [10]u8{3, 5, 2, 7, 4, 10, 1, 9, 8, 6}
const p4 = [4]u8{2, 4, 3, 1}
const ip = [8]u8{2, 6, 3, 1, 4, 8, 5, 7}
const ip_inverse = [8]u8{4, 1, 3, 5, 7, 2, 8, 6}
const expansion = [8]u8{4, 1, 2, 3, 2, 3, 4, 1}
const sboxes = [32]u8{1, 0, 3, 2, 3, 2, 1, 0, 0, 2, 1, 3, 3, 1, 3, 2, 0, 1, 2, 3, 2, 0, 1, 3, 3, 0, 1, 0, 2, 1, 0, 3}

fn table_value(table int, index int) u32 {
	match table {
		0 { return u32(p8[index]) }
		1 { return u32(p10[index]) }
		2 { return u32(ip[index]) }
		3 { return u32(ip_inverse[index]) }
		4 { return u32(expansion[index]) }
		else { return u32(p4[index]) }
	}
}

fn permute(value u32, input_bits u32, table int, count int) u32 {
	mut result := u32(0)
	for index in 0 .. count {
		position := table_value(table, index)
		result = (result << 1) | ((value >> (input_bits - position)) & 1)
	}
	return result
}

fn rotate5(value u32, amount u32) u32 {
	return ((value << amount) | (value >> (5 - amount))) & 31
}

fn subkey(key u32, round u32) u32 {
	selected := permute(key, 10, 1, 10)
	mut left := selected >> 5
	mut right := selected & 31
	left = rotate5(left, 1)
	right = rotate5(right, 1)
	if round != 0 {
		left = rotate5(left, 2)
		right = rotate5(right, 2)
	}
	return permute((left << 5) | right, 10, 0, 8)
}

fn sbox_value(box int, nibble u32) u32 {
	row := int(((nibble & 8) >> 2) | (nibble & 1))
	column := int((nibble >> 1) & 3)
	return u32(sboxes[box * 16 + row * 4 + column])
}

fn fk(state u32, key u32) u32 {
	left := state >> 4
	right := state & 15
	mixed := permute(right, 4, 4, 8) ^ key
	substituted := (sbox_value(0, mixed >> 4) << 2) | sbox_value(1, mixed & 15)
	return ((left ^ permute(substituted, 4, 5, 4)) << 4) | right
}

fn crypt(message u32, key u32, decrypt bool) u32 {
	first := subkey(key, 0)
	second := subkey(key, 1)
	mut state := permute(message, 8, 2, 8)
	if decrypt { state = fk(state, second) } else { state = fk(state, first) }
	state = ((state & 15) << 4) | (state >> 4)
	if decrypt { state = fk(state, first) } else { state = fk(state, second) }
	return permute(state, 8, 3, 8)
}

@[export: 'sdes']
pub fn sdes(input &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		if input[0] < 0 || input[0] > 1023 || input[1] < 0 || input[1] > 255 { return -1 }
		if output == nil || output_capacity < 2 { return -2 }
		key := u32(input[0])
		ciphertext := crypt(u32(input[1]), key, false)
		recovered := crypt(ciphertext, key, true)
		output[0] = u8(ciphertext)
		output[1] = u8(recovered)
		return 2
	}
}
