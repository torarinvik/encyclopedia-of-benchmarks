const max_length: usize = 128;
export fn fast_walsh_hadamard_transform(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 2 or length > max_length + 2 or (values[0] != 0 and values[0] != 1) or values[1] < 1 or values[1] > max_length) return -1;
    const n: usize = @intCast(values[1]);
    if ((n & (n - 1)) != 0 or length != n + 2) return -1;
    var a: [max_length]i64 = @splat(0);
    for (0..n) |i| { if (values[i+2] < -10000 or values[i+2] > 10000) return -1; a[i] = values[i+2]; }
    var h: usize = 1;
    while (h < n) : (h *= 2) {
        var b: usize = 0;
        while (b < n) : (b += 2*h) {
            for (0..h) |j| { const x=a[b+j]; const y=a[b+j+h]; a[b+j]=x+y; a[b+j+h]=x-y; }
        }
    }
    if (values[0] == 1) for (0..n) |i| { if (a[i] % @as(i64, @intCast(n)) != 0) return -1; a[i] = @divExact(a[i], @as(i64, @intCast(n))); };
    if (n*8 > capacity or output == null) return -2;
    for (0..n) |i| { const x: u64 = @bitCast(a[i]); for (0..8) |k| output[i*8+k] = @truncate(x >> @intCast(k*8)); }
    return @intCast(n);
}
