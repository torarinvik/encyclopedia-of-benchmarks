const MAX_PARSEABLE_INPUT_LENGTH: usize = 157;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const MASK_63: u64 = 0x7fffffffffffffff;

export fn mono_alphabetic_ciphers(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const operation = input[0];
    const raw_text_length = input[1];
    if ((operation != 0 and operation != 1) or raw_text_length < 0 or raw_text_length > 128) return -1;
    const text_length: usize = @intCast(raw_text_length);
    if (length != 28 + text_length) return -1;

    var seen: [26]bool = [_]bool{false} ** 26;
    var inverse: [26]usize = [_]usize{0} ** 26;
    for (0..26) |i| {
        const value = input[2 + i];
        if (value < 65 or value > 90) return -1;
        const index: usize = @intCast(value - 65);
        if (seen[index]) return -1;
        seen[index] = true;
        inverse[index] = i;
    }
    for (0..text_length) |i| {
        if (input[28 + i] < 32 or input[28 + i] > 126) return -1;
    }

    var hash = FNV_OFFSET_BASIS;
    const length_word: u64 = @intCast(text_length);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        hash = (hash ^ ((length_word >> shift) & 0xff)) *% FNV_PRIME;
    }
    for (0..text_length) |i| {
        const value = input[28 + i];
        var mapped: u8 = @intCast(value);
        if ((value >= 65 and value <= 90) or (value >= 97 and value <= 122)) {
            const lower = value >= 97 and value <= 122;
            const letter: usize = @intCast(if (lower) value - 97 else value - 65);
            const position = if (operation == 0) inverse[letter] else letter;
            const target: u8 = @intCast(if (operation == 0) 65 + @as(i64, @intCast(position)) else input[2 + position]);
            mapped = if (lower) target + 32 else target;
        }
        hash = (hash ^ @as(u64, mapped)) *% FNV_PRIME;
    }
    return @intCast(hash & MASK_63);
}
