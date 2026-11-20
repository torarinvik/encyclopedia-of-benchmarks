const MAX_CARDS: usize = 12;
const MAX_INPUT_WORDS: usize = 14;
const DECK_SIZE: usize = 81;

fn complementCode(a_raw: i8, b_raw: i8) usize {
    const a: usize = @intCast(a_raw);
    const b: usize = @intCast(b_raw);
    var result: usize = 0;
    var place: usize = 1;
    for (0..4) |_| {
        const digit_sum = (a / place) % 3 + (b / place) % 3;
        result += ((3 - digit_sum % 3) % 3) * place;
        place *= 3;
    }
    return result;
}

fn putI64Le(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
}

pub export fn set_puzzle_find_sets(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_WORDS) return -1;
    const raw_count = input[0];
    if (raw_count < 0 or raw_count > @as(i64, @intCast(MAX_CARDS)) or length != @as(usize, @intCast(raw_count)) + 1) return -1;

    var index_by_code: [DECK_SIZE]i8 = @splat(-1);
    var code_by_index: [MAX_CARDS]i8 = @splat(0);
    const count: usize = @intCast(raw_count);
    for (0..count) |i| {
        const code = input[i + 1];
        if (code < 0 or code >= @as(i64, @intCast(DECK_SIZE))) return -1;
        const code_index: usize = @intCast(code);
        if (index_by_code[code_index] >= 0) return -1;
        index_by_code[code_index] = @intCast(i);
        code_by_index[i] = @intCast(code);
    }

    var set_count: usize = 0;
    for (0..count) |i| {
        for (i + 1..count) |j| {
            const k = index_by_code[complementCode(code_by_index[i], code_by_index[j])];
            if (k > @as(i8, @intCast(j))) set_count += 1;
        }
    }
    const output_bytes = (1 + 3 * set_count) * 8;
    if (output == null or capacity < output_bytes) return -2;

    putI64Le(output, 0, @intCast(set_count));
    var word: usize = 1;
    for (0..count) |i| {
        for (i + 1..count) |j| {
            const k = index_by_code[complementCode(code_by_index[i], code_by_index[j])];
            if (k > @as(i8, @intCast(j))) {
                putI64Le(output, word, @intCast(i));
                putI64Le(output, word + 1, @intCast(j));
                putI64Le(output, word + 2, @intCast(k));
                word += 3;
            }
        }
    }
    return @intCast(output_bytes);
}
