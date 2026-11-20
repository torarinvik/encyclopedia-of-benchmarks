const MAX_QUERIES: usize = 32;
const WORD_MASK: u64 = 0xffff_ffff;

fn writeU64Le(output: [*c]u8, query: usize, value: u64) void {
    for (0..8) |byte| output[query * 8 + byte] = @truncate(value >> @intCast(8 * byte));
}

pub export fn multiply_shift_universal_hash_trace(
    input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize,
) i64 {
    if (input == null or length < 2 or length > 2 + 2 * MAX_QUERIES + 1) return -1;
    const width_value = input[0];
    const count_value = input[1];
    if (width_value < 1 or width_value > 16 or count_value < 0 or count_value > 32) return -1;
    const count: usize = @intCast(count_value);
    if (length != 2 + 2 * count) return -1;

    for (0..count) |query| {
        const multiplier = input[2 + 2 * query];
        const key = input[3 + 2 * query];
        if (multiplier < 1 or multiplier > 4294967295 or
            @mod(multiplier, 2) == 0) return -1;
        if (key < 0 or key > 4294967295) return -1;
    }

    const required = count * 8;
    if ((required > 0 and output == null) or capacity < required) return -2;
    const shift: u6 = @intCast(32 - width_value);
    for (0..count) |query| {
        const multiplier: u64 = @intCast(input[2 + 2 * query]);
        const key: u64 = @intCast(input[3 + 2 * query]);
        const low_word = (multiplier * key) & WORD_MASK;
        writeU64Le(output, query, low_word >> shift);
    }
    return @intCast(required);
}
