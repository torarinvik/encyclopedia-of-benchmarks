const max_n: usize = 8;
const max_size: usize = 1 << max_n;
const max_input_length: usize = 1 + 2 * max_size;
const modulus: i64 = 998244353;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn bitwise_and_convolution(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > max_input_length) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 0 or n_value > 8) return -1;
    const n: usize = @intCast(n_value);
    const size = @as(usize, 1) << @intCast(n);
    if (length != 1 + 2 * size) return -1;
    for (0..2 * size) |index| {
        const value = input[1 + index];
        if (value < 0 or value >= modulus) return -1;
    }
    const output_bytes = 8 * size;
    if (output_opt == null or capacity < output_bytes) return -2;

    var a: [max_size]i64 = @splat(0);
    var b: [max_size]i64 = @splat(0);
    for (0..size) |index| {
        a[index] = input[1 + index];
        b[index] = input[1 + size + index];
    }
    for (0..n) |bit| {
        const bit_mask = @as(usize, 1) << @intCast(bit);
        for (0..size) |mask| {
            if ((mask & bit_mask) == 0) {
                a[mask] = @mod(a[mask] + a[mask | bit_mask], modulus);
                b[mask] = @mod(b[mask] + b[mask | bit_mask], modulus);
            }
        }
    }
    for (0..size) |mask| a[mask] = @mod(a[mask] * b[mask], modulus);
    for (0..n) |bit| {
        const bit_mask = @as(usize, 1) << @intCast(bit);
        for (0..size) |mask| {
            if ((mask & bit_mask) == 0) {
                a[mask] -= a[mask | bit_mask];
                if (a[mask] < 0) a[mask] += modulus;
            }
        }
    }
    const output = output_opt.?;
    for (0..size) |mask| storeI64Le(output, 8 * mask, a[mask]);
    return @intCast(output_bytes);
}
