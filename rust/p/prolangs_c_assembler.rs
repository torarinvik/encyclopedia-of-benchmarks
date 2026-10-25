/* (c) William Landi 1991
 * Permission to use this code is granted as long as the copyright
 * notice remains in place.
 *
 * Clean-room bounded adaptation: numeric records replace the original text,
 * temporary-file, listing, and object-file interfaces; the two-pass symbol
 * and SIC/XE encoding behavior is retained for the documented subset.
 */
const MAX_RECORDS: usize = 16;
const MAX_LABELS: usize = 16;
const MODULUS: i64 = 1_000_000_007;

#[no_mangle]
pub unsafe extern "C" fn prolangs_c_assembler(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 9 || length > 65 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 2 || values[0] > MAX_RECORDS as i64 { return -1; }
    let count = values[0] as usize;
    if length != 1 + count * 4 { return -1; }
    let mut opcode = [0i64; MAX_RECORDS];
    let mut label = [0i64; MAX_RECORDS];
    let mut kind = [0i64; MAX_RECORDS];
    let mut operand = [0i64; MAX_RECORDS];
    let mut address = [0i64; MAX_RECORDS];
    let mut size = [0i64; MAX_RECORDS];
    let mut code = [0i64; MAX_RECORDS];
    let mut symbol = [0i64; MAX_LABELS + 1];
    let mut defined = [false; MAX_LABELS + 1];
    for i in 0..count {
        let offset = 1 + i * 4;
        if !(0..=11).contains(&values[offset]) || !(0..=MAX_LABELS as i64).contains(&values[offset + 1]) ||
            !(0..=5).contains(&values[offset + 2]) || !(0..=0xFFFFFF).contains(&values[offset + 3]) { return -1; }
        opcode[i] = values[offset]; label[i] = values[offset + 1]; kind[i] = values[offset + 2]; operand[i] = values[offset + 3];
    }
    if opcode[0] != 0 || opcode[count - 1] != 1 || label[0] == 0 || kind[0] != 0 || operand[0] > 0xFFFFF { return -1; }
    for i in 1..count - 1 { if opcode[i] == 0 || opcode[i] == 1 { return -1; } }
    if label[count - 1] != 0 || kind[count - 1] != 0 || operand[count - 1] != 0 { return -1; }

    let start_address = operand[0];
    let mut location = start_address;
    address[0] = location;
    defined[label[0] as usize] = true;
    symbol[label[0] as usize] = location;
    for i in 0..count {
        if i > 0 {
            address[i] = location;
            if label[i] != 0 {
                let id = label[i] as usize;
                if defined[id] || location >= 0x100000 { return -1; }
                defined[id] = true;
                symbol[id] = location;
            }
        }
        size[i] = match opcode[i] {
            0 if i == 0 => 0,
            1 if i == count - 1 => 0,
            2 if kind[i] == 0 && operand[i] <= 256 => operand[i],
            3 if kind[i] == 0 && operand[i] <= 256 => operand[i] * 3,
            4 if kind[i] == 0 => 3,
            5..=8 if (kind[i] == 1 && operand[i] <= 4095) ||
                ((kind[i] == 2 || kind[i] == 3) && (1..=MAX_LABELS as i64).contains(&operand[i])) => 3,
            9 if kind[i] == 0 && operand[i] == 0 => 3,
            10 if kind[i] == 4 && operand[i] <= 5 => 2,
            11 if kind[i] == 5 && (operand[i] >> 4) <= 5 && (operand[i] & 15) <= 5 => 2,
            _ => return -1,
        };
        if i > 0 {
            if location > 0x100000 - size[i] { return -1; }
            location += size[i];
        }
    }
    let program_length = location - start_address;
    for i in 1..count - 1 {
        code[i] = match opcode[i] {
            4 => operand[i],
            5..=8 => {
                let base: i64 = match opcode[i] { 5 => 0x00, 6 => 0x0C, 7 => 0x18, _ => 0x3C };
                let ni: i64 = match kind[i] { 1 => 1, 2 => 3, _ => 2 };
                let mut field = operand[i];
                let mut pc_relative: i64 = 0;
                if kind[i] == 2 || kind[i] == 3 {
                    let id = operand[i] as usize;
                    if !defined[id] { return -1; }
                    field = symbol[id] - (address[i] + 3);
                    if !(-2048..=2047).contains(&field) { return -1; }
                    pc_relative = 1;
                    field &= 0xFFF;
                }
                ((base | ni) * 65536) + pc_relative * 8192 + field
            }
            9 => 0x4F0000,
            10 => 0xB400 | (operand[i] << 4),
            11 => 0x9000 | operand[i],
            _ => 0,
        };
    }
    let mut checksum = (program_length * 257 + start_address * 17) % MODULUS;
    for i in 0..count {
        checksum = (checksum * 131 + (address[i] + 1) * 17 + code[i] * 3 + size[i]) % MODULUS;
    }
    checksum
}
