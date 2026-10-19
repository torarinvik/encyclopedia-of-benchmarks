const OUTPUT_BYTES = 12;
const MASK32_1: u32 = 0x55555555;
const MASK32_2: u32 = 0x33333333;
const MASK32_4: u32 = 0x0f0f0f0f;
const MASK64_1: u64 = 0x5555555555555555;
const MASK64_2: u64 = 0x3333333333333333;
const MASK64_4: u64 = 0x0f0f0f0f0f0f0f0f;

fn reverse_bits32(value: u32) u32 {
    var n = value;
    n = ((n >> 1) & MASK32_1) | ((n & MASK32_1) << 1);
    n = ((n >> 2) & MASK32_2) | ((n & MASK32_2) << 2);
    n = ((n >> 4) & MASK32_4) | ((n & MASK32_4) << 4);
    return ((n & 0xff000000) >> 24) | ((n & 0x00ff0000) >> 8) |
        ((n & 0x0000ff00) << 8) | ((n & 0x000000ff) << 24);
}

fn reverse_bits64(value: u64) u64 {
    var n = value;
    n = ((n >> 1) & MASK64_1) | ((n & MASK64_1) << 1);
    n = ((n >> 2) & MASK64_2) | ((n & MASK64_2) << 2);
    n = ((n >> 4) & MASK64_4) | ((n & MASK64_4) << 4);
    return ((n & 0xff00000000000000) >> 56) | ((n & 0x00ff000000000000) >> 40) |
        ((n & 0x0000ff0000000000) >> 24) | ((n & 0x000000ff00000000) >> 8) |
        ((n & 0x00000000ff000000) << 8) | ((n & 0x0000000000ff0000) << 24) |
        ((n & 0x000000000000ff00) << 40) | ((n & 0x00000000000000ff) << 56);
}

export fn revert_bits(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length != 2) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > 4294967295) return -1;
    if (output_opt == null or capacity < OUTPUT_BYTES) return -2;
    const output = output_opt.?;
    const reversed32 = reverse_bits32(@intCast(input[0]));
    const reversed64 = reverse_bits64(@bitCast(input[1]));
    for (0..4) |i| output[i] = @truncate(reversed32 >> @intCast(8 * i));
    for (0..8) |i| output[4 + i] = @truncate(reversed64 >> @intCast(8 * i));
    return OUTPUT_BYTES;
}
