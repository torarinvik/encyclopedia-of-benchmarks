/* (c) William Landi 1991
 * Permission to use this code is granted as long as the copyright
 * notice remains in place.
 *
 * Clean-room bounded adaptation: numeric records replace the original text,
 * temporary-file, listing, and object-file interfaces; the two-pass symbol
 * and SIC/XE encoding behavior is retained for the documented subset.
 */
module prolangs_c_assembler

const max_records = 16
const max_labels = 16
const modulus = i64(1000000007)

@[export: 'prolangs_c_assembler']
pub fn prolangs_c_assembler(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 9 || length > 65 { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > max_records { return -1 }
		count := int(input[0])
		if int(length) != 1 + count * 4 { return -1 }
		mut opcode := [max_records]i64{}
		mut label := [max_records]i64{}
		mut kind := [max_records]i64{}
		mut operand := [max_records]i64{}
		mut address := [max_records]i64{}
		mut size := [max_records]i64{}
		mut code := [max_records]i64{}
		mut symbol := [max_labels + 1]i64{}
		mut defined := [max_labels + 1]bool{}
		for i in 0 .. count {
			offset := 1 + i * 4
			if input[offset] < 0 || input[offset] > 11 || input[offset + 1] < 0 || input[offset + 1] > max_labels ||
				input[offset + 2] < 0 || input[offset + 2] > 5 || input[offset + 3] < 0 || input[offset + 3] > 0xFFFFFF { return -1 }
			opcode[i] = input[offset]
			label[i] = input[offset + 1]
			kind[i] = input[offset + 2]
			operand[i] = input[offset + 3]
		}
		if opcode[0] != 0 || opcode[count - 1] != 1 || label[0] == 0 || kind[0] != 0 || operand[0] > 0xFFFFF { return -1 }
		for i in 1 .. count - 1 { if opcode[i] == 0 || opcode[i] == 1 { return -1 } }
		if label[count - 1] != 0 || kind[count - 1] != 0 || operand[count - 1] != 0 { return -1 }

		start_address := operand[0]
		mut location := start_address
		address[0] = location
		defined[int(label[0])] = true
		symbol[int(label[0])] = location
		for i in 0 .. count {
			if i > 0 {
				address[i] = location
				if label[i] != 0 {
					id := int(label[i])
					if defined[id] || location >= 0x100000 { return -1 }
					defined[id] = true
					symbol[id] = location
				}
			}
			match opcode[i] {
				0 { if i != 0 { return -1 }; size[i] = 0 }
				1 { if i != count - 1 { return -1 }; size[i] = 0 }
				2 { if kind[i] != 0 || operand[i] > 256 { return -1 }; size[i] = operand[i] }
				3 { if kind[i] != 0 || operand[i] > 256 { return -1 }; size[i] = operand[i] * 3 }
				4 { if kind[i] != 0 { return -1 }; size[i] = 3 }
				5, 6, 7, 8 {
					if !((kind[i] == 1 && operand[i] <= 4095) || ((kind[i] == 2 || kind[i] == 3) && operand[i] >= 1 && operand[i] <= max_labels)) { return -1 }
					size[i] = 3
				}
				9 { if kind[i] != 0 || operand[i] != 0 { return -1 }; size[i] = 3 }
				10 { if kind[i] != 4 || operand[i] > 5 { return -1 }; size[i] = 2 }
				11 { if kind[i] != 5 || (operand[i] >> 4) > 5 || (operand[i] & 15) > 5 { return -1 }; size[i] = 2 }
				else { return -1 }
			}
			if i > 0 {
				if location > 0x100000 - size[i] { return -1 }
				location += size[i]
			}
		}
		program_length := location - start_address
		for i in 1 .. count - 1 {
			match opcode[i] {
				4 { code[i] = operand[i] }
				5, 6, 7, 8 {
					base := i64(0)
					if opcode[i] == 5 { base = 0 } else if opcode[i] == 6 { base = 0x0C } else if opcode[i] == 7 { base = 0x18 } else { base = 0x3C }
					ni := i64(2)
					if kind[i] == 1 { ni = 1 } else if kind[i] == 2 { ni = 3 }
					mut field := operand[i]
					mut pc_relative := i64(0)
					if kind[i] == 2 || kind[i] == 3 {
						id := int(operand[i])
						if !defined[id] { return -1 }
						field = symbol[id] - (address[i] + 3)
						if field < -2048 || field > 2047 { return -1 }
						pc_relative = 1
						field = field & 0xFFF
					}
					code[i] = (base | ni) * 65536 + pc_relative * 8192 + field
				}
				9 { code[i] = 0x4F0000 }
				10 { code[i] = 0xB400 | (operand[i] << 4) }
				11 { code[i] = 0x9000 | operand[i] }
				else {}
			}
		}
		mut checksum := (program_length * 257 + start_address * 17) % modulus
		for i in 0 .. count { checksum = (checksum * 131 + (address[i] + 1) * 17 + code[i] * 3 + size[i]) % modulus }
		return checksum
	}
}
