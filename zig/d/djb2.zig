const MAX_BYTES: usize = 64;
const MAX_PARSED_BYTES: usize = 65;
const UINT32_MODULUS: u64 = 1 << 32;

export fn djb2(input: [*c]const i64, length: usize) i64 {
    if (length > MAX_PARSED_BYTES or (length > 0 and input == null)) return -1;
    if (length > MAX_BYTES) return -1;
    var hash: u64 = 5381;
    for (0..length) |index| {
        const code_point = input[index];
        if (code_point < 0 or code_point > 255) return -1;
        hash = (hash * 33 + @as(u64, @intCast(code_point))) % UINT32_MODULUS;
    }
    return @intCast(hash);
}
