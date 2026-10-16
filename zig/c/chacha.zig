const WORDS: usize = 16;
const BYTES: usize = 64;
const MASK: u64 = 0xffff_ffff;

fn rotateLeft(value: u64, count: u6) u64 {
    return ((value << count) | (value >> (32 - count))) & MASK;
}

fn quarterRound(state: *[WORDS]u64, a: usize, b: usize, c: usize, d: usize) void {
    state[a] = (state[a] + state[b]) & MASK;
    state[d] = rotateLeft(state[d] ^ state[a], 16);
    state[c] = (state[c] + state[d]) & MASK;
    state[b] = rotateLeft(state[b] ^ state[c], 12);
    state[a] = (state[a] + state[b]) & MASK;
    state[d] = rotateLeft(state[d] ^ state[a], 8);
    state[c] = (state[c] + state[d]) & MASK;
    state[b] = rotateLeft(state[b] ^ state[c], 7);
}

export fn chacha(input: [*c]const i64, length: usize, output: [*c]u8,
    output_capacity: usize) i64 {
    if (input == null or length != WORDS) return -1;
    var initial: [WORDS]u64 = @splat(0);
    for (0..WORDS) |index| {
        if (input[index] < 0 or input[index] > 0xffff_ffff) return -1;
        initial[index] = @intCast(input[index]);
    }
    if (output == null or output_capacity < BYTES) return -2;

    var state = initial;
    for (0..10) |_| {
        quarterRound(&state, 0, 4, 8, 12);
        quarterRound(&state, 1, 5, 9, 13);
        quarterRound(&state, 2, 6, 10, 14);
        quarterRound(&state, 3, 7, 11, 15);
        quarterRound(&state, 0, 5, 10, 15);
        quarterRound(&state, 1, 6, 11, 12);
        quarterRound(&state, 2, 7, 8, 13);
        quarterRound(&state, 3, 4, 9, 14);
    }
    for (0..WORDS) |index| {
        const word: u32 = @intCast((state[index] + initial[index]) & MASK);
        output[4 * index] = @truncate(word);
        output[4 * index + 1] = @truncate(word >> 8);
        output[4 * index + 2] = @truncate(word >> 16);
        output[4 * index + 3] = @truncate(word >> 24);
    }
    return BYTES;
}
