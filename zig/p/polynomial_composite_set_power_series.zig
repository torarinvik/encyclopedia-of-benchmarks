const MODULUS: i64 = 998244353;
const MAX_COEFFICIENTS: usize = 8;
const MAX_N: usize = 4;
const MAX_SIZE: usize = 16;
const MAX_INPUT: usize = 27;

fn storeLe(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn polynomial_composite_set_power_series(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    if (input[0] < 0 or input[0] > MAX_COEFFICIENTS or
        input[1] < 0 or input[1] > MAX_N) return -1;
    const count: usize = @intCast(input[0]);
    const n: usize = @intCast(input[1]);
    const size: usize = @as(usize, 1) << @intCast(n);
    if (length != 2 + count + size) return -1;
    for (0..count + size) |index|
        if (input[2 + index] < 0 or input[2 + index] >= MODULUS) return -1;

    const bytes = 8 * size;
    if (output == null or capacity < bytes) return -2;

    var series = [_]i64{0} ** MAX_SIZE;
    var result = [_]i64{0} ** MAX_SIZE;
    var temporary = [_]i64{0} ** MAX_SIZE;
    for (0..size) |mask| series[mask] = input[2 + count + mask];

    var degree = count;
    while (degree > 0) : (degree -= 1) {
        for (0..size) |mask| {
            var total: i64 = 0;
            var subset = mask;
            while (true) {
                total = @mod(total + result[subset] * series[mask ^ subset], MODULUS);
                if (subset == 0) break;
                subset = (subset - 1) & mask;
            }
            temporary[mask] = total;
        }
        temporary[0] = @mod(temporary[0] + input[1 + degree], MODULUS);
        for (0..size) |mask| result[mask] = temporary[mask];
    }
    for (0..size) |mask| storeLe(output, 8 * mask, result[mask]);
    return @intCast(bytes);
}
