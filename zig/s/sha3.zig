const MAX_MESSAGE_BYTES: usize = 4096;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 4099;
const MAX_OUTPUT_BYTES: usize = 64;
const ROUND_CONSTANTS = [_]u64{
    0x0000000000000001, 0x0000000000008082, 0x800000000000808a, 0x8000000080008000,
    0x000000000000808b, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
    0x000000000000008a, 0x0000000000000088, 0x0000000080008009, 0x000000008000000a,
    0x000000008000808b, 0x800000000000008b, 0x8000000080008089, 0x8000000000008003,
    0x8000000000008002, 0x8000000000000080, 0x000000000000800a, 0x800000008000000a,
    0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
};
const ROTATION_OFFSETS = [_]u32{
    0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43,
    25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14,
};

fn rotateLeft(value: u64, amount: u32) u64 {
    if (amount == 0) return value;
    const left_shift: u6 = @intCast(amount);
    const right_shift: u6 = @intCast(64 - amount);
    return (value << left_shift) | (value >> right_shift);
}

fn keccakF(state: *[25]u64) void {
    for (ROUND_CONSTANTS) |round_constant| {
        var column = [_]u64{0} ** 5;
        var delta = [_]u64{0} ** 5;
        var moved = [_]u64{0} ** 25;
        for (0..5) |x| column[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20];
        for (0..5) |x| delta[x] = column[(x + 4) % 5] ^ rotateLeft(column[(x + 1) % 5], 1);
        for (0..5) |y| {
            for (0..5) |x| state[x + 5 * y] ^= delta[x];
        }

        for (0..5) |y| {
            for (0..5) |x| {
                const source = x + 5 * y;
                const target = y + 5 * ((2 * x + 3 * y) % 5);
                moved[target] = rotateLeft(state[source], ROTATION_OFFSETS[source]);
            }
        }
        for (0..5) |y| {
            for (0..5) |x| {
                state[x + 5 * y] = moved[x + 5 * y] ^
                    ((~moved[(x + 1) % 5 + 5 * y]) & moved[(x + 2) % 5 + 5 * y]);
            }
        }
        state[0] ^= round_constant;
    }
}

fn absorbByte(state: *[25]u64, offset: usize, value: u8) void {
    state[offset / 8] ^= @as(u64, value) << @as(u6, @intCast((offset % 8) * 8));
}

fn sha3Digest(variant: usize, values: [*]const i64) [64]u8 {
    const digest_lengths = [_]usize{ 28, 32, 48, 64 };
    const rates = [_]usize{ 144, 136, 104, 72 };
    const message_length: usize = @intCast(values[1]);
    const rate = rates[variant];
    var state = [_]u64{0} ** 25;
    var offset: usize = 0;
    while (message_length - offset >= rate) {
        for (0..rate) |index| absorbByte(&state, index, @intCast(values[2 + offset + index]));
        keccakF(&state);
        offset += rate;
    }

    var block = [_]u8{0} ** 144;
    const remaining = message_length - offset;
    for (0..remaining) |index| block[index] = @intCast(values[2 + offset + index]);
    block[remaining] ^= 0x06;
    block[rate - 1] ^= 0x80;
    for (0..rate) |index| absorbByte(&state, index, block[index]);
    keccakF(&state);

    var digest = [_]u8{0} ** 64;
    for (0..digest_lengths[variant]) |index|
        digest[index] = @truncate(state[index / 8] >> @as(u6, @intCast((index % 8) * 8)));
    return digest;
}

export fn sha3(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (values[0] < 0 or values[0] > 3 or values[1] < 0 or
        values[1] > @as(i64, @intCast(MAX_MESSAGE_BYTES))) return -1;
    const variant: usize = @intCast(values[0]);
    const message_length: usize = @intCast(values[1]);
    if (input_length != 2 + message_length) return -1;
    for (0..message_length) |index| {
        if (values[2 + index] < 0 or values[2 + index] > 255) return -1;
    }

    const digest_lengths = [_]usize{ 28, 32, 48, 64 };
    const digest_length = digest_lengths[variant];
    if (digest_length > MAX_OUTPUT_BYTES) return -1;
    const out = output orelse return -2;
    if (output_capacity < digest_length) return -2;
    const digest = sha3Digest(variant, values);
    for (0..digest_length) |index| out[index] = digest[index];
    return @intCast(digest_length);
}
