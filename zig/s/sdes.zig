const P8 = [_]u8{6, 3, 7, 4, 8, 5, 10, 9};
const P10 = [_]u8{3, 5, 2, 7, 4, 10, 1, 9, 8, 6};
const P4 = [_]u8{2, 4, 3, 1};
const IP = [_]u8{2, 6, 3, 1, 4, 8, 5, 7};
const IP_INVERSE = [_]u8{4, 1, 3, 5, 7, 2, 8, 6};
const EXPANSION = [_]u8{4, 1, 2, 3, 2, 3, 4, 1};
const SBOXES = [_]u8{1, 0, 3, 2, 3, 2, 1, 0, 0, 2, 1, 3, 3, 1, 3, 2, 0, 1, 2, 3, 2, 0, 1, 3, 3, 0, 1, 0, 2, 1, 0, 3};

fn tableValue(table: usize, index: usize) u32 {
    return switch (table) {
        0 => P8[index],
        1 => P10[index],
        2 => IP[index],
        3 => IP_INVERSE[index],
        4 => EXPANSION[index],
        else => P4[index],
    };
}

fn permute(value: u32, input_bits: u32, table: usize, count: usize) u32 {
    var result: u32 = 0;
    for (0..count) |index| {
        const position = tableValue(table, index);
        result = (result << 1) | ((value >> @as(u5, @intCast(input_bits - position))) & 1);
    }
    return result;
}

fn rotate5(value: u32, amount: u5) u32 {
    return ((value << amount) | (value >> (5 - amount))) & 31;
}

fn subkey(key: u32, round: u32) u32 {
    const selected = permute(key, 10, 1, 10);
    var left = selected >> 5;
    var right = selected & 31;
    left = rotate5(left, 1);
    right = rotate5(right, 1);
    if (round != 0) {
        left = rotate5(left, 2);
        right = rotate5(right, 2);
    }
    return permute((left << 5) | right, 10, 0, 8);
}

fn sboxValue(box: usize, nibble: u32) u32 {
    const row: usize = @intCast(((nibble & 8) >> 2) | (nibble & 1));
    const column: usize = @intCast((nibble >> 1) & 3);
    return SBOXES[box * 16 + row * 4 + column];
}

fn fk(state: u32, key: u32) u32 {
    const left = state >> 4;
    const right = state & 15;
    const mixed = permute(right, 4, 4, 8) ^ key;
    const substituted = (sboxValue(0, mixed >> 4) << 2) | sboxValue(1, mixed & 15);
    return ((left ^ permute(substituted, 4, 5, 4)) << 4) | right;
}

fn crypt(message: u32, key: u32, decrypt: bool) u32 {
    const first = subkey(key, 0);
    const second = subkey(key, 1);
    var state = permute(message, 8, 2, 8);
    state = fk(state, if (decrypt) second else first);
    state = ((state & 15) << 4) | (state >> 4);
    state = fk(state, if (decrypt) first else second);
    return permute(state, 8, 3, 8);
}

/// Return ciphertext and the plaintext recovered with the reversed subkeys.
export fn sdes(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length != 2) return -1;
    if (input[0] < 0 or input[0] > 1023 or input[1] < 0 or input[1] > 255) return -1;
    if (output == null or output_capacity < 2) return -2;
    const key: u32 = @intCast(input[0]);
    const ciphertext = crypt(@intCast(input[1]), key, false);
    const recovered = crypt(ciphertext, key, true);
    output[0] = @intCast(ciphertext);
    output[1] = @intCast(recovered);
    return 2;
}
