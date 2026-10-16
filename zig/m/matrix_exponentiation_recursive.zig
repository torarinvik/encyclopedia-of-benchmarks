const Matrix2 = [4]i64;
fn multiply(a: Matrix2, b: Matrix2) Matrix2 {
    var c = [_]i64{0, 0, 0, 0};
    for (0..2) |r| for (0..2) |col| for (0..2) |k| { c[r*2+col] += a[r*2+k] * b[k*2+col]; };
    return c;
}
fn power(a: Matrix2, e: i64) Matrix2 {
    if (e == 0) return .{1, 0, 0, 1};
    if (@mod(e, 2) == 1) return multiply(power(a, e - 1), a);
    const half = power(a, @divTrunc(e, 2));
    return multiply(half, half);
}
fn store(value: i64, out: []u8, offset: usize) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[offset+b] = @truncate(bits >> @intCast(8*b));
}
export fn matrix_exponentiation_recursive(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length != 5) return -2;
    const v = input.?[0..5];
    if (v[0] < 0 or v[0] > 30) return -2;
    for (v[1..]) |x| { if (x < -1 or x > 1) return -2; }
    if (output == null or capacity < 32) return -3;
    const result = power(.{v[1], v[2], v[3], v[4]}, v[0]);
    const out = output.?[0..32];
    for (result, 0..) |x, i| store(x, out, i*8);
    return 4;
}
