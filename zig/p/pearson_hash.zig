const TABLE_SIZE: usize = 256;
const MAX_TEXT: usize = 64;
const MAX_WORDS: usize = 1 + TABLE_SIZE + MAX_TEXT;

export fn pearson_hash(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 + TABLE_SIZE or length > MAX_WORDS + 1) return -1;
    const declared = input[0];
    if (declared < 0 or declared > MAX_TEXT or
        length != 1 + TABLE_SIZE + @as(usize, @intCast(declared))) return -1;

    var table: [TABLE_SIZE]u8 = undefined;
    var used = [_]bool{false} ** TABLE_SIZE;
    for (0..TABLE_SIZE) |slot| {
        const value = input[1 + slot];
        if (value < 0 or value > 255) return -1;
        const byte: usize = @intCast(value);
        if (used[byte]) return -1;
        used[byte] = true;
        table[slot] = @intCast(value);
    }

    const text_start = 1 + TABLE_SIZE;
    const text_length: usize = @intCast(declared);
    for (0..text_length) |offset| {
        const value = input[text_start + offset];
        if (value < 0 or value > 255) return -1;
    }
    var state: u8 = 0;
    for (0..text_length) |offset| {
        const byte: u8 = @intCast(input[text_start + offset]);
        state = table[@as(usize, state ^ byte)];
    }
    return state;
}
