const MAX_N: usize = 8;
const MAX_SIZE: usize = 1 << MAX_N;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_SIZE;
const MODULUS: i64 = 998244353;

fn xorWalshTransform(values: *[MAX_SIZE]i64, size: usize) void {
    var half: usize = 1;
    while (half < size) : (half *= 2) {
        var block: usize = 0;
        while (block < size) : (block += 2 * half) {
            for (0..half) |offset| {
                const left = values[block + offset];
                const right = values[block + half + offset];
                values[block + offset] = @mod(left + right, MODULUS);
                values[block + half + offset] = @mod(left - right + MODULUS, MODULUS);
            }
        }
    }
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn bitwise_xor_convolution(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 0 or n_value > MAX_N) return -1;
    const n: usize = @intCast(n_value);
    const size = @as(usize, 1) << @intCast(n);
    if (length != 1 + 2 * size) return -1;
    for (0..2 * size) |index| {
        const value = input[1 + index];
        if (value < 0 or value >= MODULUS) return -1;
    }

    const output_bytes = 8 * size;
    if (output_opt == null or capacity < output_bytes) return -2;
    var first: [MAX_SIZE]i64 = @splat(0);
    var second: [MAX_SIZE]i64 = @splat(0);
    for (0..size) |index| {
        first[index] = input[1 + index];
        second[index] = input[1 + size + index];
    }
    xorWalshTransform(&first, size);
    xorWalshTransform(&second, size);
    for (0..size) |index| first[index] = @mod(first[index] * second[index], MODULUS);
    xorWalshTransform(&first, size);

    var inverse_size: i64 = 1;
    for (0..n) |_| inverse_size = @mod(inverse_size * ((MODULUS + 1) / 2), MODULUS);
    const output = output_opt.?;
    for (0..size) |index|
        storeI64Le(output, 8 * index, @mod(first[index] * inverse_size, MODULUS));
    return @intCast(output_bytes);
}
