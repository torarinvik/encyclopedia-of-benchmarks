const KEY_BYTES: usize = 32;
const BLOCK_BYTES: usize = 16;
const INPUT_BYTES: usize = KEY_BYTES + BLOCK_BYTES;

fn gfMul(left_value: u8, right_value: u8) u8 {
    var left = left_value;
    var right = right_value;
    var result: u8 = 0;
    while (right != 0) {
        if ((right & 1) != 0) result ^= left;
        const doubled = (@as(u16, left) << 1) ^ (if ((left & 0x80) != 0) @as(u16, 0x1b) else @as(u16, 0));
        left = @truncate(doubled);
        right >>= 1;
    }
    return result;
}

fn gfPow(value_value: u8, exponent_value: u32) u8 {
    var value = value_value;
    var exponent = exponent_value;
    var result: u8 = 1;
    while (exponent != 0) {
        if ((exponent & 1) != 0) result = gfMul(result, value);
        value = gfMul(value, value);
        exponent >>= 1;
    }
    return result;
}

fn rotl8(value: u8, amount: usize) u8 {
    const left_shift: u4 = @intCast(amount);
    const right_shift: u4 = @intCast(8 - amount);
    return @truncate((@as(u16, value) << left_shift) | (@as(u16, value) >> right_shift));
}

fn makeSbox() [256]u8 {
    var sbox: [256]u8 = undefined;
    for (0..256) |value| {
        const inverse: u8 = if (value == 0) 0 else gfPow(@intCast(value), 254);
        sbox[value] = inverse ^ rotl8(inverse, 1) ^ rotl8(inverse, 2) ^
            rotl8(inverse, 3) ^ rotl8(inverse, 4) ^ 0x63;
    }
    return sbox;
}

fn encryptBlock(key: [KEY_BYTES]u8, block: [BLOCK_BYTES]u8) [BLOCK_BYTES]u8 {
    const sbox = makeSbox();
    const round_constants = [_]u8{ 1, 2, 4, 8, 16, 32, 64 };
    var round_keys: [240]u8 = undefined;
    for (0..KEY_BYTES) |index| round_keys[index] = key[index];
    var written: usize = KEY_BYTES;
    while (written < round_keys.len) {
        const word = written / 4;
        var temporary = [4]u8{
            round_keys[written - 4], round_keys[written - 3],
            round_keys[written - 2], round_keys[written - 1],
        };
        if (word % 8 == 0) {
            const first = temporary[0];
            temporary[0] = sbox[temporary[1]] ^ round_constants[word / 8 - 1];
            temporary[1] = sbox[temporary[2]];
            temporary[2] = sbox[temporary[3]];
            temporary[3] = sbox[first];
        } else if (word % 8 == 4) {
            for (0..4) |index| temporary[index] = sbox[temporary[index]];
        }
        for (0..4) |index| {
            round_keys[written] = round_keys[written - KEY_BYTES] ^ temporary[index];
            written += 1;
        }
    }

    var state = block;
    for (0..BLOCK_BYTES) |index| state[index] ^= round_keys[index];
    for (1..14) |round| {
        for (0..BLOCK_BYTES) |index| state[index] = sbox[state[index]];
        const previous = state;
        for (0..4) |column| {
            for (0..4) |row| state[row + 4 * column] = previous[row + 4 * ((column + row) % 4)];
        }
        for (0..4) |column| {
            const offset = 4 * column;
            const a = state[offset];
            const b = state[offset + 1];
            const c = state[offset + 2];
            const d = state[offset + 3];
            const total = a ^ b ^ c ^ d;
            state[offset] = a ^ total ^ gfMul(a ^ b, 2);
            state[offset + 1] = b ^ total ^ gfMul(b ^ c, 2);
            state[offset + 2] = c ^ total ^ gfMul(c ^ d, 2);
            state[offset + 3] = d ^ total ^ gfMul(d ^ a, 2);
        }
        const key_offset = round * BLOCK_BYTES;
        for (0..BLOCK_BYTES) |index| state[index] ^= round_keys[key_offset + index];
    }
    for (0..BLOCK_BYTES) |index| state[index] = sbox[state[index]];
    const previous = state;
    for (0..4) |column| {
        for (0..4) |row| state[row + 4 * column] = previous[row + 4 * ((column + row) % 4)];
    }
    for (0..BLOCK_BYTES) |index| state[index] ^= round_keys[224 + index];
    return state;
}

pub export fn mibench_security_rijndael(values: ?[*]const i64, input_length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    const input = values orelse return -1;
    if (input_length != INPUT_BYTES) return -1;
    for (0..INPUT_BYTES) |index| if (input[index] < 0 or input[index] > 255) return -1;
    const out = output orelse return -2;
    if (output_capacity < BLOCK_BYTES) return -2;
    var key: [KEY_BYTES]u8 = undefined;
    var block: [BLOCK_BYTES]u8 = undefined;
    for (0..KEY_BYTES) |index| key[index] = @intCast(input[index]);
    for (0..BLOCK_BYTES) |index| block[index] = @intCast(input[KEY_BYTES + index]);
    const ciphertext = encryptBlock(key, block);
    for (0..BLOCK_BYTES) |index| out[index] = ciphertext[index];
    return @intCast(BLOCK_BYTES);
}
