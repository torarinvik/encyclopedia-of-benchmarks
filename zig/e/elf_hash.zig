/// Hash a bounded ASCII codepoint array with the Python ELF recurrence.
const MAX_CODEPOINTS: usize = 8;

export fn elf_hash(input: [*c]const i64, length: usize) i64 {
    if (length > MAX_CODEPOINTS or (input == null and length != 0)) return -1;
    var hash: u64 = 0;
    for (0..length) |index| {
        const codepoint = input[index];
        if (codepoint < 0 or codepoint > 127) return -1;
        hash = (hash << 4) + @as(u64, @intCast(codepoint));
        const high = hash & 0xF0000000;
        if (high != 0) hash ^= high >> 24;
        hash ^= high;
    }
    return @intCast(hash);
}
