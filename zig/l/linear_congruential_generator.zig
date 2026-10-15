fn putU64Le(output: [*c]u8, offset: usize, value: u64) void {
    for (0..8) |byte| output[offset + byte] = @truncate(value >> @intCast(byte * 8));
}

pub export fn linear_congruential_generator(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 5) return -1;
    const seed = input[0]; const multiplier = input[1]; const increment = input[2]; const modulo = input[3]; const count = input[4];
    if (modulo < 2 or modulo > 4_294_967_296 or seed < 0 or seed >= modulo or multiplier < 0 or multiplier > 65_535 or increment < 0 or increment > 4_294_967_295 or count < 0 or count > 512) return -1;
    const n: usize = @intCast(count); const required = n * 8;
    if (capacity < required or (required > 0 and output == null)) return -2;
    var state: u64 = @intCast(seed);
    for (0..n) |i| {
        state = (@as(u64, @intCast(multiplier)) * state + @as(u64, @intCast(increment))) % @as(u64, @intCast(modulo));
        putU64Le(output, i * 8, state);
    }
    return @intCast(required);
}
