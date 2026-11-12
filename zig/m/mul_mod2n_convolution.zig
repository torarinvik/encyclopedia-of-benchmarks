const MaxN: i64 = 5;
const MaxP: usize = 32;
const MaxInput: usize = 66;
const MaxOutput: usize = 256;
const Mod: i64 = 998_244_353;

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn mul_mod2n_convolution(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MaxInput) return -1;
    const input = input_opt.?;
    const n0 = input[0];
    if (n0 < 0 or n0 > MaxN) return -1;
    const p: usize = @as(usize, 1) << @intCast(n0);
    if (length != 1 + 2 * p) return -1;
    for (input[1..length]) |x| if (x < 0 or x >= Mod) return -1;
    const bytes = 8 * p;
    if (bytes > MaxOutput) return -1;
    if (output_opt == null or capacity < bytes) return -2;
    var a: [MaxP]i64 = [_]i64{0} ** MaxP;
    var b: [MaxP]i64 = [_]i64{0} ** MaxP;
    var result: [MaxP]i64 = [_]i64{0} ** MaxP;
    for (0..p) |i| { a[i] = input[1+i]; b[i] = input[1+p+i]; }
    const mask = p - 1;
    for (0..p) |i| for (0..p) |j| {
        const k = (i * j) & mask;
        result[k] = (result[k] + a[i] * b[j]) % Mod;
    };
    const output = output_opt.?;
    for (0..p) |i| storeLe(output, 8*i, result[i]);
    return @intCast(bytes);
}
