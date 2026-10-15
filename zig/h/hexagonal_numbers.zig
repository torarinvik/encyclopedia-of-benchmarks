/// Emit the zero-based hexagonal number sequence as little-endian i64 values.
const MAX_LENGTH: i64 = 1024;
const BYTES_PER_VALUE: usize = 8;

fn storeI64Le(output: [*]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..BYTES_PER_VALUE) |byte|
        output[position + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn hexagonal_numbers(length: i64, output: [*]u8,
    output_capacity: usize) i64 {
    if (length < 1 or length > MAX_LENGTH) return -1;
    const n: usize = @intCast(length);
    const required = n * BYTES_PER_VALUE;
    if (output_capacity < required) return -2;
    for (0..n) |index| {
        const i: i64 = @intCast(index);
        storeI64Le(output, index * BYTES_PER_VALUE, i * (2 * i - 1));
    }
    return length;
}
