const MAX_TEXT_LENGTH: usize = 256;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 285;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const MASK_63: u64 = 0x7fffffffffffffff;

export fn mono_alphabetic(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const operation = input[0];
    const raw_text_length = input[1];
    if ((operation != 0 and operation != 1) or raw_text_length < 1
        or raw_text_length > @as(i64, @intCast(MAX_TEXT_LENGTH))) return -1;
    const text_length: usize = @intCast(raw_text_length);
    if (length != 28 + text_length) return -1;

    var seen: [26]bool = [_]bool{false} ** 26;
    var inverse: [26]u8 = [_]u8{0} ** 26;
    for (0..26) |i| {
        const value = input[2 + i];
        if (value < 65 or value > 90) return -1;
        const index: usize = @intCast(value - 65);
        if (seen[index]) return -1;
        seen[index] = true;
        inverse[index] = @intCast(i);
    }
    for (0..text_length) |i| {
        if (input[28 + i] < 65 or input[28 + i] > 90) return -1;
    }

    var hash = FNV_OFFSET_BASIS;
    const length_word: u64 = @intCast(text_length);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        hash = (hash ^ ((length_word >> shift) & 0xff)) *% FNV_PRIME;
    }
    for (0..text_length) |i| {
        const index: usize = @intCast(input[28 + i] - 65);
        const mapped: u8 = if (operation == 0) @intCast(input[2 + index]) else 65 + inverse[index];
        hash = (hash ^ @as(u64, mapped)) *% FNV_PRIME;
    }
    return @intCast(hash & MASK_63);
}
