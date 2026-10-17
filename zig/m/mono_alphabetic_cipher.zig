const MAX_PARSEABLE_INPUT_LENGTH: usize = 183;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const MASK_63: u64 = 0x7fffffffffffffff;

export fn mono_alphabetic_cipher(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const operation = input[0];
    const raw_text_length = input[1];
    if ((operation != 0 and operation != 1) or raw_text_length < 0
        or raw_text_length > 128) return -1;
    const text_length: usize = @intCast(raw_text_length);
    if (length != 54 + text_length) return -1;

    var key_seen: [26]bool = [_]bool{false} ** 26;
    var alphabet_seen: [26]bool = [_]bool{false} ** 26;
    var key_inverse: [26]usize = [_]usize{0} ** 26;
    var alphabet_inverse: [26]usize = [_]usize{0} ** 26;
    for (0..26) |i| {
        const key_value = input[2 + i];
        const alphabet_value = input[28 + i];
        if (key_value < 65 or key_value > 90 or alphabet_value < 65 or alphabet_value > 90) return -1;
        const key_index: usize = @intCast(key_value - 65);
        const alphabet_index: usize = @intCast(alphabet_value - 65);
        if (key_seen[key_index] or alphabet_seen[alphabet_index]) return -1;
        key_seen[key_index] = true;
        alphabet_seen[alphabet_index] = true;
        key_inverse[key_index] = i;
        alphabet_inverse[alphabet_index] = i;
    }
    var output_length: usize = 0;
    for (0..text_length) |i| {
        const value = input[54 + i];
        if (value != 32 and (value < 48 or value > 57) and
            (value < 65 or value > 90) and (value < 97 or value > 122)) return -1;
        if (value < 48 or value > 57) output_length += 1;
    }

    var hash = FNV_OFFSET_BASIS;
    const length_word: u64 = @intCast(output_length);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        hash = (hash ^ ((length_word >> shift) & 0xff)) *% FNV_PRIME;
    }
    for (0..text_length) |i| {
        const value = input[54 + i];
        if (value >= 48 and value <= 57) continue;
        var mapped: u8 = @intCast(value);
        if (value != 32) {
            const lower = value >= 97 and value <= 122;
            const letter: usize = @intCast(if (lower) value - 97 else value - 65);
            const position = if (operation == 0) alphabet_inverse[letter] else key_inverse[letter];
            const target: u8 = @intCast(if (operation == 0) input[2 + position] else input[28 + position]);
            mapped = if (lower) target + 32 else target;
        }
        hash = (hash ^ @as(u64, mapped)) *% FNV_PRIME;
    }
    return @intCast(hash & MASK_63);
}
