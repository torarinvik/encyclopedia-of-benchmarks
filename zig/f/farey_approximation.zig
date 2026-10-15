fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(byte * 8)) & 0xff);
}

export fn farey_approximation(values: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length != 2) return -1;
    const input = values.?[0..length];
    const decimal_millionths = input[0];
    const repeat = input[1];
    if (decimal_millionths < 1 or decimal_millionths > 999999 or repeat < 1 or repeat > 20) return -1;
    if (output == null or output_capacity < 16) return -2;
    const result = output.?[0..output_capacity];

    const decimal = @as(f64, @floatFromInt(decimal_millionths)) / 1_000_000.0;
    var a: i64 = 0;
    var b: i64 = 1;
    var c: i64 = 1;
    var d: i64 = 1;
    var numerator: i64 = 0;
    var denominator: i64 = 0;
    var iteration: i64 = 0;
    while (iteration < repeat) : (iteration += 1) {
        numerator = a + c;
        denominator = b + d;
        if (decimal > @as(f64, @floatFromInt(numerator)) / @as(f64, @floatFromInt(denominator))) {
            a = numerator;
            b = denominator;
        } else {
            c = numerator;
            d = denominator;
        }
    }
    storeI64Le(result.ptr, 0, numerator);
    storeI64Le(result.ptr, 8, denominator);
    return 16;
}
