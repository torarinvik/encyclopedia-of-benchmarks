const MODULUS: i64 = 998244353;
const MAX_N: usize = 5;
const MAX_SIZE: usize = 32;
const MAX_INPUT: usize = 33;

fn subsetSize(mask: usize) usize { return @popCount(mask); }

fn storeLe(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn exp_of_set_power_series(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    if (input[0] < 0 or input[0] > MAX_N) return -1;
    const n: usize = @intCast(input[0]);
    const size: usize = @as(usize, 1) << @intCast(n);
    if (length != 1 + size or input[1] != 0) return -1;
    for (0..size) |mask| if (input[1 + mask] < 0 or input[1 + mask] >= MODULUS) return -1;

    const bytes = 8 * size;
    if (output == null or capacity < bytes) return -2;

    var inverse = [_]i64{0} ** (MAX_N + 1);
    var values = [_]i64{0} ** MAX_SIZE;
    if (n > 0) inverse[1] = 1;
    for (2..n + 1) |k| {
        inverse[k] = MODULUS - (MODULUS / @as(i64, @intCast(k))) *
            inverse[@intCast(@mod(MODULUS, @as(i64, @intCast(k))))] % MODULUS;
    }
    values[0] = 1;
    for (1..size) |mask| {
        var total: i64 = 0;
        var subset = mask;
        while (subset != 0) {
            var term = @as(i64, @intCast(subsetSize(subset))) * input[1 + subset] % MODULUS;
            term = term * values[mask ^ subset] % MODULUS;
            total = (total + term) % MODULUS;
            subset = (subset - 1) & mask;
        }
        values[mask] = total * inverse[subsetSize(mask)] % MODULUS;
    }
    for (0..size) |mask| storeLe(output, 8 * mask, values[mask]);
    return @intCast(bytes);
}
