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

export fn prolangs_c_assembler(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 9 or length > 65 or values[0] < 2 or values[0] > @as(i64, @intCast(MAX_RECORDS))) return -1;
    const count: usize = @intCast(values[0]);
    if (length != 1 + count * 4) return -1;
    var opcode: [MAX_RECORDS]i64 = @splat(0);
    var label: [MAX_RECORDS]i64 = @splat(0);
    var kind: [MAX_RECORDS]i64 = @splat(0);
    var operand: [MAX_RECORDS]i64 = @splat(0);
    var address: [MAX_RECORDS]i64 = @splat(0);
    var size: [MAX_RECORDS]i64 = @splat(0);
    var code: [MAX_RECORDS]i64 = @splat(0);
    var symbol: [MAX_LABELS + 1]i64 = @splat(0);
    var defined: [MAX_LABELS + 1]bool = @splat(false);
    for (0..count) |i| {
        const offset = 1 + i * 4;
        if (values[offset] < 0 or values[offset] > 11 or values[offset + 1] < 0 or values[offset + 1] > @as(i64, @intCast(MAX_LABELS)) or
            values[offset + 2] < 0 or values[offset + 2] > 5 or values[offset + 3] < 0 or values[offset + 3] > 0xFFFFFF) return -1;
        opcode[i] = values[offset]; label[i] = values[offset + 1]; kind[i] = values[offset + 2]; operand[i] = values[offset + 3];
    }
    if (opcode[0] != 0 or opcode[count - 1] != 1 or label[0] == 0 or kind[0] != 0 or operand[0] > 0xFFFFF) return -1;
    for (1..count - 1) |i| { if (opcode[i] == 0 or opcode[i] == 1) return -1; }
    if (label[count - 1] != 0 or kind[count - 1] != 0 or operand[count - 1] != 0) return -1;

    const start_address = operand[0];
    var location = start_address;
    address[0] = location;
    defined[@intCast(label[0])] = true;
    symbol[@intCast(label[0])] = location;
    for (0..count) |i| {
        if (i > 0) {
            address[i] = location;
            if (label[i] != 0) {
                const id: usize = @intCast(label[i]);
                if (defined[id] or location >= 0x100000) return -1;
                defined[id] = true;
                symbol[id] = location;
            }
        }
        switch (opcode[i]) {
            0 => { if (i != 0) return -1; size[i] = 0; },
            1 => { if (i != count - 1) return -1; size[i] = 0; },
            2 => { if (kind[i] != 0 or operand[i] > 256) return -1; size[i] = operand[i]; },
            3 => { if (kind[i] != 0 or operand[i] > 256) return -1; size[i] = operand[i] * 3; },
            4 => { if (kind[i] != 0) return -1; size[i] = 3; },
            5, 6, 7, 8 => {
                if (!((kind[i] == 1 and operand[i] <= 4095) or ((kind[i] == 2 or kind[i] == 3) and operand[i] >= 1 and operand[i] <= MAX_LABELS))) return -1;
                size[i] = 3;
            },
            9 => { if (kind[i] != 0 or operand[i] != 0) return -1; size[i] = 3; },
            10 => { if (kind[i] != 4 or operand[i] > 5) return -1; size[i] = 2; },
            11 => { if (kind[i] != 5 or (operand[i] >> 4) > 5 or (operand[i] & 15) > 5) return -1; size[i] = 2; },
            else => return -1,
        }
        if (i > 0) {
            if (location > 0x100000 - size[i]) return -1;
            location += size[i];
        }
    }
    const program_length = location - start_address;
    for (1..count - 1) |i| {
        switch (opcode[i]) {
            4 => code[i] = operand[i],
            5, 6, 7, 8 => {
                const base: i64 = if (opcode[i] == 5) 0x00 else if (opcode[i] == 6) 0x0C else if (opcode[i] == 7) 0x18 else 0x3C;
                const ni: i64 = if (kind[i] == 1) 1 else if (kind[i] == 2) 3 else 2;
                var field = operand[i];
                var pc_relative: i64 = 0;
                if (kind[i] == 2 or kind[i] == 3) {
                    const id: usize = @intCast(operand[i]);
                    if (!defined[id]) return -1;
                    field = symbol[id] - (address[i] + 3);
                    if (field < -2048 or field > 2047) return -1;
                    pc_relative = 1;
                    field = @as(i64, @intCast(@as(u64, @bitCast(field)) & 0xFFF));
                }
                code[i] = (base | ni) * 65536 + pc_relative * 8192 + field;
            },
            9 => code[i] = 0x4F0000,
            10 => code[i] = 0xB400 | (operand[i] << 4),
            11 => code[i] = 0x9000 | operand[i],
            else => {},
        }
    }
    var checksum = (program_length * 257 + start_address * 17) % MODULUS;
    for (0..count) |i| checksum = (checksum * 131 + (address[i] + 1) * 17 + code[i] * 3 + size[i]) % MODULUS;
    return checksum;
}
