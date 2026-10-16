const q12_offset: i64 = 10_000_000_000;
const q6_divisor: i64 = 1_000_000;

fn roundDivEven(numerator: i64, denominator: i64) i64 {
    const negative = numerator < 0;
    const magnitude: u64 = @intCast(if (negative) -numerator else numerator);
    const divisor: u64 = @intCast(denominator);
    var quotient = magnitude / divisor;
    const remainder = magnitude % divisor;
    if (remainder * 2 > divisor or (remainder * 2 == divisor and (quotient & 1) != 0)) quotient += 1;
    const rounded: i64 = @intCast(quotient);
    return if (negative) -rounded else rounded;
}

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

pub export fn barnsley_fern(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1) return -1;
    const iteration_value = input[0];
    if (iteration_value < 1 or iteration_value > 4096 or length != @as(usize, @intCast(iteration_value))) return -1;
    const iterations: usize = @intCast(iteration_value);
    for (1..iterations) |step| {
        const sample = input[step];
        if (sample < 0 or sample >= 10_000) return -1;
    }
    const output_length = iterations * 16;
    if (output == null or capacity < output_length) return -2;

    var x: i64 = 0;
    var y: i64 = 0;
    putI64Le(output, 0, 0);
    putI64Le(output, 8, 0);
    for (1..iterations) |step| {
        const sample = input[step];
        var a: i64 = 0;
        var b: i64 = 0;
        var c: i64 = 0;
        var d: i64 = 0;
        var f: i64 = 0;
        if (sample < 100) {
            d = 16;
        } else if (sample < 8_600) {
            a = 85; b = 4; c = -4; d = 85; f = 160;
        } else if (sample < 9_300) {
            a = 20; b = -26; c = 23; d = 22; f = 160;
        } else {
            a = -15; b = 28; c = 26; d = 24; f = 44;
        }
        const next_x = roundDivEven(a * x + b * y, 100);
        const next_y = roundDivEven(c * x + d * y, 100) + f * q12_offset;
        x = next_x;
        y = next_y;
        putI64Le(output, step * 16, roundDivEven(x, q6_divisor));
        putI64Le(output, step * 16 + 8, roundDivEven(y, q6_divisor));
    }
    return @intCast(output_length);
}
