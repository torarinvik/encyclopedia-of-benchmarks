// Clean-room bounded QR encoder; package README documents source provenance.
// SPDX-License-Identifier: GPL-3.0-or-later
module qrduino

const qr_side = 25
const qr_cells = 625
const data_words = 34
const ecc_words = 10
const max_message = 21
const prefix_bytes = 22

fn gf_multiply(left_input u8, right_input u8) u8 {
	mut left := u16(left_input)
	mut right := right_input
	mut product := u16(0)
	for right != 0 {
		if right & 1 != 0 { product ^= left }
		right >>= 1
		left <<= 1
		if left & 0x100 != 0 { left ^= 0x11d }
	}
	return u8(product)
}

fn put_bits(mut target [data_words]u8, mut position int, value u32, width int) {
	for bit := width; bit > 0; bit-- {
		if (value >> u32(bit - 1)) & 1 != 0 {
			target[position / 8] |= u8(0x80 >> u32(position & 7))
		}
		position++
	}
}

fn mark(mut frame [qr_cells]u8, mut reserved [qr_cells]u8, x int, y int, dark bool) {
	if x < 0 || x >= qr_side || y < 0 || y >= qr_side { return }
	index := y * qr_side + x
	reserved[index] = 1
	if dark { frame[index] = 1 }
}

fn finder(mut frame [qr_cells]u8, mut reserved [qr_cells]u8, left int, top int) {
	mark(mut frame, mut reserved, left + 3, top + 3, true)
	for j in 0 .. 6 {
		mark(mut frame, mut reserved, left + j, top, true)
		mark(mut frame, mut reserved, left, top + j + 1, true)
		mark(mut frame, mut reserved, left + 6, top + j, true)
		mark(mut frame, mut reserved, left + j + 1, top + 6, true)
	}
	for j in 1 .. 5 {
		mark(mut frame, mut reserved, left + j, top + 1, false)
		mark(mut frame, mut reserved, left + 1, top + j + 1, false)
		mark(mut frame, mut reserved, left + 5, top + j, false)
		mark(mut frame, mut reserved, left + j + 1, top + 5, false)
	}
	for j in 2 .. 4 {
		mark(mut frame, mut reserved, left + j, top + 2, true)
		mark(mut frame, mut reserved, left + 2, top + j + 1, true)
		mark(mut frame, mut reserved, left + 4, top + j, true)
		mark(mut frame, mut reserved, left + j + 1, top + 4, true)
	}
}

fn alignment(mut frame [qr_cells]u8, mut reserved [qr_cells]u8, cx int, cy int) {
	mark(mut frame, mut reserved, cx, cy, true)
	for j in -2 .. 2 {
		mark(mut frame, mut reserved, cx + j, cy - 2, true)
		mark(mut frame, mut reserved, cx - 2, cy + j + 1, true)
		mark(mut frame, mut reserved, cx + 2, cy + j, true)
		mark(mut frame, mut reserved, cx + j + 1, cy + 2, true)
	}
	for j in 0 .. 2 {
		mark(mut frame, mut reserved, cx - 1, cy + j, false)
		mark(mut frame, mut reserved, cx + 1, cy - j, false)
		mark(mut frame, mut reserved, cx - j, cy - 1, false)
		mark(mut frame, mut reserved, cx + j, cy + 1, false)
	}
}

fn base_frame(mut frame [qr_cells]u8, mut reserved [qr_cells]u8) {
	finder(mut frame, mut reserved, 0, 0)
	finder(mut frame, mut reserved, qr_side - 7, 0)
	finder(mut frame, mut reserved, 0, qr_side - 7)
	alignment(mut frame, mut reserved, 18, 18)
	mark(mut frame, mut reserved, 8, qr_side - 8, true)
	for x in 0 .. 9 { mark(mut frame, mut reserved, x, 8, false) }
	for x in 0 .. 8 {
		mark(mut frame, mut reserved, x + qr_side - 8, 8, false)
		mark(mut frame, mut reserved, 8, x, false)
	}
	for y in 0 .. 7 { mark(mut frame, mut reserved, 8, y + qr_side - 7, false) }
	for p in 0 .. qr_side - 14 {
		dark := p & 1 == 0
		mark(mut frame, mut reserved, 8 + p, 6, dark)
		mark(mut frame, mut reserved, 6, 8 + p, dark)
	}
	for y in 0 .. qr_side {
		for x in 0 .. y + 1 {
			index := y * qr_side + x
			if frame[index] != 0 { reserved[index] = 1 }
		}
	}
}

fn make_codewords(message [max_message]u8, length int, mut words [data_words + ecc_words]u8) {
	mut data := [data_words]u8{}
	mut position := 0
	put_bits(mut data, mut position, 4, 4)
	put_bits(mut data, mut position, u32(length), 8)
	for i in 0 .. length { put_bits(mut data, mut position, u32(message[i]), 8) }
	remaining := data_words * 8 - position
	put_bits(mut data, mut position, 0, if remaining < 4 { remaining } else { 4 })
	for position & 7 != 0 { put_bits(mut data, mut position, 0, 1) }
	mut pad := u32(0xec)
	for position < data_words * 8 {
		put_bits(mut data, mut position, pad, 8)
		pad = if pad == 0xec { u32(0x11) } else { u32(0xec) }
	}
	mut generator := [ecc_words + 1]u8{}
	generator[0] = 1
	mut degree := 0
	mut root := u8(1)
	for _ in 0 .. ecc_words {
		generator[degree + 1] = 1
		for j := degree; j > 0; j-- {
			prior := generator[j - 1]
			current := generator[j]
			generator[j] = if current != 0 { prior ^ gf_multiply(current, root) } else { prior }
		}
		generator[0] = gf_multiply(generator[0], root)
		degree++
		root = gf_multiply(root, 2)
	}
	mut ecc := [ecc_words]u8{}
	for i in 0 .. data_words {
		factor := data[i] ^ ecc[0]
		for j in 0 .. ecc_words - 1 {
			ecc[j] = ecc[j + 1] ^ gf_multiply(factor, generator[j + 1])
		}
		ecc[ecc_words - 1] = gf_multiply(factor, generator[0])
	}
	for i in 0 .. data_words { words[i] = data[i] }
	for i in 0 .. ecc_words { words[data_words + i] = ecc[i] }
}

fn place_data(mut frame [qr_cells]u8, reserved [qr_cells]u8, words [data_words + ecc_words]u8) {
	mut x := qr_side - 1
	mut y := qr_side - 1
	mut moving_up := true
	mut moving_left := true
	for i in 0 .. data_words + ecc_words {
		mut byte := words[i]
		for _ in 0 .. 8 {
			if byte & 0x80 != 0 { frame[y * qr_side + x] = 1 }
			byte <<= 1
			for {
				if moving_left { x-- }
				else {
					x++
					if moving_up {
						if y != 0 { y-- }
						else {
							x -= 2
							moving_up = false
							if x == 6 { x--; y = 9 }
						}
					} else if y != qr_side - 1 { y++ }
					else {
						x -= 2
						moving_up = true
						if x == 6 { x--; y -= 8 }
					}
				}
				moving_left = !moving_left
				if reserved[y * qr_side + x] == 0 { break }
			}
		}
	}
}

fn masked_by(mask int, x int, y int) bool {
	product := x * y
	match mask {
		0 { return (x + y) % 2 == 0 }
		1 { return y % 2 == 0 }
		2 { return x % 3 == 0 }
		3 { return (x + y) % 3 == 0 }
		4 { return (y / 2 + x / 3) % 2 == 0 }
		5 { return product % 2 + product % 3 == 0 }
		6 { return (product % 2 + product % 3) % 2 == 0 }
		else { return ((x + y) % 2 + product % 3) % 2 == 0 }
	}
}

fn add_format(mut candidate [qr_cells]u8, mask int) {
	data := u32(8 | mask)
	mut remainder := data << 10
	for bit := 14; bit >= 10; bit-- {
		if remainder & (u32(1) << u32(bit)) != 0 { remainder ^= u32(0x537) << u32(bit - 10) }
	}
	word := ((data << 10) | remainder) ^ u32(0x5412)
	for bit in 0 .. 6 { candidate[bit * qr_side + 8] = u8((word >> u32(bit)) & 1) }
	candidate[7 * qr_side + 8] = u8((word >> 6) & 1)
	candidate[8 * qr_side + 8] = u8((word >> 7) & 1)
	candidate[8 * qr_side + 7] = u8((word >> 8) & 1)
	for bit in 9 .. 15 { candidate[8 * qr_side + 14 - bit] = u8((word >> u32(bit)) & 1) }
	for bit in 0 .. 8 { candidate[8 * qr_side + qr_side - 1 - bit] = u8((word >> u32(bit)) & 1) }
	for bit in 8 .. 15 { candidate[(qr_side - 15 + bit) * qr_side + 8] = u8((word >> u32(bit)) & 1) }
	candidate[(qr_side - 8) * qr_side + 8] = 1
}

fn penalty(matrix [qr_cells]u8) u32 {
	mut score := u32(0)
	mut dark := u32(0)
	for value in matrix { dark += u32(value) }
	for axis in 0 .. 2 {
		for line in 0 .. qr_side {
			mut run := 1
			for step in 1 .. qr_side {
				a := if axis == 1 { matrix[step * qr_side + line] } else { matrix[line * qr_side + step] }
				b := if axis == 1 { matrix[(step - 1) * qr_side + line] } else { matrix[line * qr_side + step - 1] }
				if a == b { run++ }
				else {
					if run >= 5 { score += u32(run - 2) }
					run = 1
				}
			}
			if run >= 5 { score += u32(run - 2) }
			for start in 0 .. qr_side - 10 {
				mut pattern := u32(0)
				for j in 0 .. 11 {
					value := if axis == 1 { matrix[(start + j) * qr_side + line] } else { matrix[line * qr_side + start + j] }
					pattern = (pattern << 1) | u32(value)
				}
				if pattern == 0x05d || pattern == 0x5d0 { score += 40 }
			}
		}
	}
	for y in 0 .. qr_side - 1 {
		for x in 0 .. qr_side - 1 {
			value := matrix[y * qr_side + x]
			if value == matrix[y * qr_side + x + 1] &&
				value == matrix[(y + 1) * qr_side + x] &&
				value == matrix[(y + 1) * qr_side + x + 1] { score += 3 }
		}
	}
	total := u32(qr_cells)
	balance := if dark * 20 > total * 10 { dark * 20 - total * 10 } else { total * 10 - dark * 20 }
	return score + balance / total * 10
}

fn evaluate_masks(frame [qr_cells]u8, reserved [qr_cells]u8) int {
	mut best_score := u32(0xffffffff)
	mut best_mask := 0
	for mask in 0 .. 8 {
		mut candidate := frame
		for i in 0 .. qr_cells {
			if reserved[i] == 0 && masked_by(mask, i % qr_side, i / qr_side) { candidate[i] ^= 1 }
		}
		add_format(mut candidate, mask)
		score := penalty(candidate)
		if score < best_score { best_score = score; best_mask = mask }
	}
	return best_mask
}

@[export: 'qrduino']
pub fn qrduino(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > max_message + 2 { return -1 }
		if input[0] < 1 || input[0] > max_message || input_length != usize(input[0] + 1) { return -1 }
		message_length := int(input[0])
		mut message := [max_message]u8{}
		for i in 0 .. message_length {
			if input[i + 1] < 1 || input[i + 1] > 127 { return -1 }
			message[i] = u8(input[i + 1])
		}
		if output == nil || output_capacity < prefix_bytes { return -2 }
		mut words := [data_words + ecc_words]u8{}
		mut frame := [qr_cells]u8{}
		mut reserved := [qr_cells]u8{}
		mut staged := [prefix_bytes]u8{}
		make_codewords(message, message_length, mut words)
		base_frame(mut frame, mut reserved)
		place_data(mut frame, reserved, words)
		for y in 0 .. 6 {
			for x in 0 .. qr_side {
				byte_index := y * 4 + x / 8
				if byte_index < prefix_bytes && frame[y * qr_side + x] != 0 {
					staged[byte_index] |= u8(0x80 >> (x & 7))
				}
			}
		}
		_ = evaluate_masks(frame, reserved)
		for i in 0 .. prefix_bytes { output[i] = staged[i] }
		return prefix_bytes
	}
}
