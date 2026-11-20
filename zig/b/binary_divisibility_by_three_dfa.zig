/// Decide binary divisibility by three with a three-state streaming DFA.
pub export fn binary_divisibility_by_three_dfa(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    output_capacity: usize,
) i64 {
    if (input == null or length == 0 or length > 4098) return -1;
    const bit_count = input[0];
    if (bit_count < 1 or bit_count > 4096 or length != @as(usize, @intCast(bit_count)) + 1) return -1;
    const bits = input[1..length];
    var remainder: i64 = 0;
    for (bits) |bit| {
        if (bit != 0 and bit != 1) return -1;
        remainder = @mod(2 * remainder + bit, 3);
    }
    if (output == null or output_capacity < 1) return -2;

    output[0] = if (remainder == 0) 1 else 0;
    return 1;
}
