/* (c) William Landi 1991
 * Permission to use this code is granted as long as the copyright
 * notice remains in place.
 *
 * Clean-room bounded adaptation: numeric records replace the original text,
 * temporary-file, listing, and object-file interfaces; the two-pass symbol
 * and SIC/XE encoding behavior is retained for the documented subset.
 */
package prolangs_c_assembler

import "core:c"

MAX_RECORDS :: 16
MAX_LABELS :: 16
MODULUS :: i64(1000000007)

@(export)
prolangs_c_assembler :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 9 || length > 65 do return -1
    if input[0] < 2 || input[0] > MAX_RECORDS do return -1
    count := int(input[0])
    if int(length) != 1 + count * 4 do return -1
    opcode, label, kind, operand, address, size: [MAX_RECORDS]int = {}
    code: [MAX_RECORDS]i64 = {}
    symbol: [MAX_LABELS+1]i64 = {}
    defined: [MAX_LABELS+1]bool = {}
    for i := 0; i < count; i += 1 {
        offset := 1 + i * 4
        if input[offset] < 0 || input[offset] > 11 || input[offset+1] < 0 || input[offset+1] > MAX_LABELS ||
            input[offset+2] < 0 || input[offset+2] > 5 || input[offset+3] < 0 || input[offset+3] > 0xFFFFFF do return -1
        opcode[i] = int(input[offset]); label[i] = int(input[offset+1])
        kind[i] = int(input[offset+2]); operand[i] = int(input[offset+3])
    }
    if opcode[0] != 0 || opcode[count-1] != 1 || label[0] == 0 || kind[0] != 0 || operand[0] > 0xFFFFF do return -1
    for i := 1; i < count-1; i += 1 { if opcode[i] == 0 || opcode[i] == 1 do return -1 }
    if label[count-1] != 0 || kind[count-1] != 0 || operand[count-1] != 0 do return -1

    location := operand[0]
    start_address := location
    address[0] = location
    defined[label[0]] = true
    symbol[label[0]] = i64(location)
    for i := 0; i < count; i += 1 {
        if i > 0 {
            address[i] = location
            if label[i] != 0 {
                if defined[label[i]] || location >= 0x100000 do return -1
                defined[label[i]] = true
                symbol[label[i]] = i64(location)
            }
        }
        switch opcode[i] {
        case 0: if i != 0 do return -1; size[i] = 0
        case 1: if i != count-1 do return -1; size[i] = 0
        case 2: if kind[i] != 0 || operand[i] > 256 do return -1; size[i] = operand[i]
        case 3: if kind[i] != 0 || operand[i] > 256 do return -1; size[i] = operand[i] * 3
        case 4: if kind[i] != 0 do return -1; size[i] = 3
        case 5, 6, 7, 8:
            if !((kind[i] == 1 && operand[i] <= 4095) || ((kind[i] == 2 || kind[i] == 3) && operand[i] >= 1 && operand[i] <= MAX_LABELS)) do return -1
            size[i] = 3
        case 9: if kind[i] != 0 || operand[i] != 0 do return -1; size[i] = 3
        case 10: if kind[i] != 4 || operand[i] > 5 do return -1; size[i] = 2
        case 11: if kind[i] != 5 || (operand[i] >> 4) > 5 || (operand[i] & 15) > 5 do return -1; size[i] = 2
        }
        if i > 0 {
            if location > 0x100000 - size[i] do return -1
            location += size[i]
        }
    }
    program_length := location - start_address
    for i := 1; i < count-1; i += 1 {
        switch opcode[i] {
        case 4: code[i] = i64(operand[i])
        case 5, 6, 7, 8:
            base := 0
            if opcode[i] == 5 do base = 0x00 else if opcode[i] == 6 do base = 0x0C else if opcode[i] == 7 do base = 0x18 else base = 0x3C
            ni := 2
            if kind[i] == 1 do ni = 1 else if kind[i] == 2 do ni = 3
            field := operand[i]
            pc_relative := 0
            if kind[i] == 2 || kind[i] == 3 {
                if !defined[operand[i]] do return -1
                field = int(symbol[operand[i]]) - (address[i] + 3)
                if field < -2048 || field > 2047 do return -1
                pc_relative = 1
                field &= 0xFFF
            }
            code[i] = i64(base|ni)*65536 + i64(pc_relative)*8192 + i64(field)
        case 9: code[i] = 0x4F0000
        case 10: code[i] = 0xB400 | (i64(operand[i]) << 4)
        case 11: code[i] = 0x9000 | i64(operand[i])
        }
    }
    checksum := (i64(program_length)*257 + i64(start_address)*17) % MODULUS
    for i := 0; i < count; i += 1 {
        checksum = (checksum * 131 + (i64(address[i])+1)*17 + code[i]*3 + i64(size[i])) % MODULUS
    }
    return checksum
}
