const max_message_bytes: i64 = 4096;

fn rotateRight(value: u64, count: u32) u64 {
    const shift: u6 = @intCast(count);
    const complement: u6 = @intCast(64 - count);
    return (value >> shift) | (value << complement);
}

fn permute(state: *[5]u64, rounds: u32) void {
    const constants = [_]u64{ 0xf0, 0xe1, 0xd2, 0xc3, 0xb4, 0xa5,
        0x96, 0x87, 0x78, 0x69, 0x5a, 0x4b };
    const first: usize = if (rounds == 12) 0 else 4;
    for (first..12) |round| {
        const x0 = state[0];
        const x1 = state[1];
        const x2 = state[2];
        const x3 = state[3];
        const x4 = state[4];
        const c = constants[round];
        const t0 = x0 ^ x1 ^ x2 ^ x3 ^ c ^ (x1 & (x0 ^ x2 ^ x4 ^ c));
        const t1 = x0 ^ x2 ^ x3 ^ x4 ^ c ^ ((x1 ^ x2 ^ c) & (x1 ^ x3));
        const t2 = x1 ^ x2 ^ x4 ^ c ^ (x3 & x4);
        const t3 = x0 ^ x1 ^ x2 ^ c ^ (~x0 & (x3 ^ x4));
        const t4 = x1 ^ x3 ^ x4 ^ ((x0 ^ x4) & x1);
        state[0] = t0 ^ rotateRight(t0, 19) ^ rotateRight(t0, 28);
        state[1] = t1 ^ rotateRight(t1, 39) ^ rotateRight(t1, 61);
        state[2] = ~(t2 ^ rotateRight(t2, 1) ^ rotateRight(t2, 6));
        state[3] = t3 ^ rotateRight(t3, 10) ^ rotateRight(t3, 17);
        state[4] = t4 ^ rotateRight(t4, 7) ^ rotateRight(t4, 41);
    }
}

fn writeU64Be(output: [*c]u8, offset: usize, value: u64) void {
    for (0..8) |byte| output[offset + byte] = @truncate(value >> @intCast(56 - byte * 8));
}

pub export fn ascon_digest(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const variant = input[0];
    const message_length_value = input[1];
    if ((variant != 0 and variant != 1) or message_length_value < 0 or
        message_length_value > max_message_bytes or length != @as(usize, @intCast(message_length_value)) + 2)
        return -1;
    const message_length: usize = @intCast(message_length_value);
    for (0..message_length) |index| if (input[index + 2] < 0 or input[index + 2] > 255) return -1;

    var state: [5]u64 = undefined;
    if (variant == 0) {
        state = .{ 0xee9398aadb67f03d, 0x8bb21831c60f1002, 0xb48a92db98d5da62,
            0x43189921b8f8e3e8, 0x348fa5c9d525e140 };
    } else {
        state = .{ 0x01470194fc6528a6, 0x738ec38ac0adffa7, 0x2ec8e3296c76384c,
            0xd6f6a54d7f52377d, 0xa13c42a223be8d87 };
    }
    const rounds: u32 = if (variant == 0) 12 else 8;
    const complete_length = message_length - message_length % 8;
    var offset: usize = 0;
    while (offset < complete_length) : (offset += 8) {
        var word: u64 = 0;
        for (0..8) |byte| word = (word << 8) | @as(u64, @intCast(input[offset + byte + 2]));
        state[0] ^= word;
        permute(&state, rounds);
    }
    const tail_length = message_length - complete_length;
    const pad_shift: u6 = @intCast(56 - tail_length * 8);
    var final_word: u64 = @as(u64, 0x80) << pad_shift;
    for (0..tail_length) |byte| {
        final_word |= @as(u64, @intCast(input[complete_length + byte + 2])) << @intCast(56 - byte * 8);
    }
    state[0] ^= final_word;
    permute(&state, 12);

    if (output == null or capacity < 32) return -2;
    for (0..4) |block| {
        writeU64Be(output, block * 8, state[0]);
        if (block != 3) permute(&state, rounds);
    }
    return 32;
}
