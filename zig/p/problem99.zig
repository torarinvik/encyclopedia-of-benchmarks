const MAX_PAIR_COUNT: i64 = 1000;
const MAX_BASE: i64 = 1_000_000;
const MAX_EXPONENT: i64 = 1_200_000;

pub export fn problem99(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1) return -1;
    const pair_count_value = input[0];
    if (pair_count_value < 0 or pair_count_value > MAX_PAIR_COUNT) return -1;
    const pair_count: usize = @intCast(pair_count_value);
    if (length != 1 + 2 * pair_count) return -1;

    var largest: f64 = 0.0;
    var result: i64 = 0;
    for (0..pair_count) |index| {
        const base = input[1 + 2 * index];
        const exponent = input[2 + 2 * index];
        if (base < 1 or base > MAX_BASE or exponent < 0 or exponent > MAX_EXPONENT) return -1;
        const value = @as(f64, @floatFromInt(exponent)) * @log10(@as(f64, @floatFromInt(base)));
        if (value > largest) {
            largest = value;
            result = @intCast(index + 1);
        }
    }
    return result;
}
