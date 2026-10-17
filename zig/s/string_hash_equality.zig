const MAX_PARSEABLE_INPUT_LENGTH: usize = 131;
const RATE_BYTES: usize = 136;
const ROUND_CONSTANTS = [_]u64{
    0x0000000000000001,
    0x0000000000008082,
    0x800000000000808a,
    0x8000000080008000,
    0x000000000000808b,
    0x0000000080000001,
    0x8000000080008081,
    0x8000000000008009,
    0x000000000000008a,
    0x0000000000000088,
    0x0000000080008009,
    0x000000008000000a,
    0x000000008000808b,
    0x800000000000008b,
    0x8000000000008089,
    0x8000000000008003,
    0x8000000000008002,
    0x8000000000000080,
    0x000000000000800a,
    0x800000008000000a,
    0x8000000080008081,
    0x8000000000008080,
    0x0000000080000001,
    0x8000000080008008
};
const ROTATION_OFFSETS = [_]u32{0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43, 25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14};

fn rotateLeft(value: u64, amount: u32) u64 {
    if (amount == 0) return value;
    return (value << @intCast(amount)) | (value >> @intCast(64 - amount));
}

fn keccakF1600(state: *[25]u64) void {
    for (0..24) |round| {
        var column: [5]u64 = @splat(0);
        var delta: [5]u64 = @splat(0);
        for (0..5) |x| column[x] = state.*[x] ^ state.*[x + 5] ^ state.*[x + 10] ^ state.*[x + 15] ^ state.*[x + 20];
        for (0..5) |x| delta[x] = column[(x + 4) % 5] ^ rotateLeft(column[(x + 1) % 5], 1);
        var moved: [25]u64 = @splat(0);
        for (0..5) |y| {
            for (0..5) |x| {
                const source = x + 5 * y;
                const target = y + 5 * ((2 * x + 3 * y) % 5);
                moved[target] = rotateLeft(state.*[source] ^ delta[x], ROTATION_OFFSETS[source]);
            }
        }
        for (0..5) |y| {
            for (0..5) |x| {
                state.*[x + 5 * y] = moved[x + 5 * y] ^ ((~moved[(x + 1) % 5 + 5 * y]) & moved[(x + 2) % 5 + 5 * y]);
            }
        }
        state.*[0] ^= ROUND_CONSTANTS[round];
    }
}

fn keccak256Bytes(values: []const i64, start: usize, byte_length: usize) [4]u64 {
    var block: [RATE_BYTES]u8 = @splat(0);
    for (0..byte_length) |i| block[i] = @intCast(values[start + i]);
    block[byte_length] ^= 0x01;
    block[RATE_BYTES - 1] ^= 0x80;
    var state: [25]u64 = @splat(0);
    for (0..RATE_BYTES / 8) |lane| {
        for (0..8) |byte| state[lane] |= @as(u64, block[lane * 8 + byte]) << @intCast(8 * byte);
    }
    keccakF1600(&state);
    return .{ state[0], state[1], state[2], state[3] };
}

export fn string_hash_equality(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 64 or values[1] < 0 or values[1] > 64) return -1;
    const length_a: usize = @intCast(values[0]);
    const length_b: usize = @intCast(values[1]);
    if (length != 2 + length_a + length_b) return -1;
    for (values[2..]) |byte| if (byte < 0 or byte > 255) return -1;
    const digest_a = keccak256Bytes(values, 2, length_a);
    const digest_b = keccak256Bytes(values, 2 + length_a, length_b);
    for (0..4) |lane| if (digest_a[lane] != digest_b[lane]) return 0;
    return 1;
}
