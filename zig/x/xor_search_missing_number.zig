const MAX_N: i64 = 255;
const MAX_INPUT_LENGTH: usize = 257;

export fn xor_search_missing_number(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const n_value = input[0];
    if (n_value < 0 or n_value > MAX_N or length != @as(usize, @intCast(n_value + 1))) return -1;
    const n: usize = @intCast(n_value);
    var seen: [256]bool = @splat(false);
    var result = n_value;
    for (0..n) |i| {
        const value = input[i + 1];
        if (value < 0 or value > n_value or seen[@intCast(value)]) return -1;
        seen[@intCast(value)] = true;
        result ^= @as(i64, @intCast(i)) ^ value;
    }
    return result;
}
