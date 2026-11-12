const MODULUS: i64 = 998244353;
const MAX_N: usize = 4;
const MAX_M: usize = 8;
const MAX_SIZE: usize = 16;
const MAX_INPUT: usize = 35;

fn storeLe(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn power_projection_of_set_power_series(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_N)) or
        input[1] < 0 or input[1] > @as(i64, @intCast(MAX_M))) return -1;
    const n: usize = @intCast(input[0]);
    const powers: usize = @intCast(input[1]);
    const size: usize = @as(usize, 1) << @intCast(n);
    if (length != 2 + 2 * size) return -1;

    var series = [_]i64{0} ** MAX_SIZE;
    var weights = [_]i64{0} ** MAX_SIZE;
    for (0..size) |mask| {
        const a = input[2 + mask];
        const w = input[2 + size + mask];
        if (a < 0 or a >= MODULUS or w < 0 or w >= MODULUS) return -1;
        series[mask] = a;
        weights[mask] = w;
    }

    const bytes = 8 * powers;
    if (output == null or capacity < bytes) return -2;

    var first = [_]i64{0} ** MAX_SIZE;
    var second = [_]i64{0} ** MAX_SIZE;
    var current = &first;
    var next = &second;
    current[0] = 1;
    for (0..powers) |power| {
        var projection: i64 = 0;
        for (0..size) |mask| projection = @mod(projection + weights[mask] * current[mask], MODULUS);
        storeLe(output, 8 * power, projection);
        if (power + 1 == powers) break;
        for (0..size) |mask| {
            var total: i64 = 0;
            var subset = mask;
            while (true) {
                total = @mod(total + current[subset] * series[mask ^ subset], MODULUS);
                if (subset == 0) break;
                subset = (subset - 1) & mask;
            }
            next[mask] = total;
        }
        const temporary = current;
        current = next;
        next = temporary;
    }
    return @intCast(bytes);
}
