/// Count alternating triples as each possible last building arrives.
const MAX_LENGTH: usize = 4096;

export fn number_of_ways_to_select_buildings(values: [*c]const i64, length: usize) i64 {
    if (length == 0) return 0;
    if (values == null or length > MAX_LENGTH) return -1;
    var different_bits: u64 = 0;
    var ways: u64 = 0;
    var zeros: u32 = 0;
    var ones: u32 = 0;
    var zero_one: u32 = 0;
    var one_zero: u32 = 0;
    for (0..length) |index| {
        const value = @as(u64, @bitCast(values[index])) ^ 48;
        different_bits |= value;
        const is_one = value & 1 != 0;
        ways += if (is_one) one_zero else zero_one;
        zero_one += if (is_one) zeros else 0;
        one_zero += if (is_one) 0 else ones;
        zeros += @intFromBool(!is_one);
        ones += @intFromBool(is_one);
    }
    if (different_bits > 1) return -1;
    return @intCast(ways);
}
