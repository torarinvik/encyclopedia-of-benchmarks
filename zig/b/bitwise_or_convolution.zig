const MaxN: usize = 8;
const MaxSize: usize = 1 << MaxN;
const MaxInput: usize = 1 + 2 * MaxSize;
const Modulus: i64 = 998_244_353;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn bitwise_or_convolution(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MaxInput) return -1;
    const input = input_opt.?;
    const nv = input[0];
    if (nv < 0 or nv > MaxN) return -1;
    const n: usize = @intCast(nv);
    const size = @as(usize, 1) << @intCast(n);
    if (length != 1 + 2 * size) return -1;
    for (0..2 * size) |i| if (input[1 + i] < 0 or input[1 + i] >= Modulus) return -1;
    const bytes = 8 * size;
    if (output_opt == null or capacity < bytes) return -2;
    var a: [MaxSize]i64 = @splat(0);
    var b: [MaxSize]i64 = @splat(0);
    for (0..size) |i| { a[i] = input[1 + i]; b[i] = input[1 + size + i]; }
    for (0..n) |bit| {
        const bit_mask = @as(usize, 1) << @intCast(bit);
        for (0..size) |mask| if ((mask & bit_mask) != 0) {
            a[mask] = @mod(a[mask] + a[mask ^ bit_mask], Modulus);
            b[mask] = @mod(b[mask] + b[mask ^ bit_mask], Modulus);
        };
    }
    for (0..size) |i| a[i] = @mod(a[i] * b[i], Modulus);
    for (0..n) |bit| {
        const bit_mask = @as(usize, 1) << @intCast(bit);
        for (0..size) |mask| if ((mask & bit_mask) != 0) {
            a[mask] = @mod(a[mask] - a[mask ^ bit_mask] + Modulus, Modulus);
        };
    }
    const output = output_opt.?;
    for (0..size) |i| storeI64Le(output, 8 * i, a[i]);
    return @intCast(bytes);
}
