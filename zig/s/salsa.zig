const WORD_COUNT: usize = 16;
const OUTPUT_BYTES: usize = 64;

fn add32(left: u32, right: u32) u32 {
    return left +% right;
}

fn rotateLeft(value: u32, amount: u5) u32 {
    return (value << amount) | (value >> (32 - amount));
}

fn quarterRound(state: *[WORD_COUNT]u32, first: usize, second: usize, third: usize, fourth: usize) void {
    state.*[second] ^= rotateLeft(add32(state.*[first], state.*[fourth]), 7);
    state.*[third] ^= rotateLeft(add32(state.*[second], state.*[first]), 9);
    state.*[fourth] ^= rotateLeft(add32(state.*[third], state.*[second]), 13);
    state.*[first] ^= rotateLeft(add32(state.*[fourth], state.*[third]), 18);
}

fn storeU32Le(output: [*]u8, offset: usize, value: u32) void {
    for (0..4) |byte| output[offset + byte] = @truncate(value >> @as(u5, @intCast(byte * 8)));
}

/// Reproduce the pinned 16-word Salsa core variant; this is not a stream cipher.
export fn salsa(input: [*c]const i32, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length != WORD_COUNT) return -1;
    var original: [WORD_COUNT]u32 = undefined;
    for (0..WORD_COUNT) |index| {
        original[index] = @bitCast(input[index]);
    }
    if (output == null or output_capacity < OUTPUT_BYTES) return -2;

    var state = original;
    for (0..10) |_| {
        quarterRound(&state, 0, 4, 8, 12);
        quarterRound(&state, 5, 9, 13, 1);
        quarterRound(&state, 10, 14, 2, 6);
        quarterRound(&state, 15, 3, 7, 11);
        quarterRound(&state, 0, 1, 2, 3);
        quarterRound(&state, 5, 6, 7, 4);
        quarterRound(&state, 10, 11, 8, 9);
        quarterRound(&state, 15, 12, 13, 14);
    }
    for (0..WORD_COUNT) |index| {
        state[index] +%= original[index];
        storeU32Le(output, index * 4, state[index]);
    }
    return OUTPUT_BYTES;
}
