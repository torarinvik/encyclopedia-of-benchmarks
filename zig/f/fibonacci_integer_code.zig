export fn fibonacci_integer_code(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 33) return -1;
    const n0 = input[0];
    if (n0 < 1 or n0 > 32 or length != @as(usize, @intCast(n0)) + 1) return -1;
    const n: usize = @intCast(n0);
    for (0..n) |i| if (input[i + 1] < 0 or input[i + 1] > 1000000) return -1;
    var fib = [_]u64{0} ** 30; fib[0] = 1; fib[1] = 2; var fib_count: usize = 2;
    while (fib_count < 30 and fib[fib_count - 1] + fib[fib_count - 2] <= 1000001) : (fib_count += 1) {
        fib[fib_count] = fib[fib_count - 1] + fib[fib_count - 2];
    }
    var staged = [_]u8{0} ** 960; var out: usize = 0;
    for (0..n) |v| {
        var remaining: u64 = @intCast(input[v + 1] + 1);
        var top: usize = 0;
        while (top + 1 < fib_count and fib[top + 1] <= remaining) : (top += 1) {}
        var bits = [_]u8{0} ** 30;
        var j = top + 1;
        while (j > 0) {
            j -= 1;
            if (fib[j] <= remaining) { bits[j] = 1; remaining -= fib[j]; }
        }
        for (0..top + 1) |i| { staged[out] = '0' + bits[i]; out += 1; }
        staged[out] = '1'; out += 1;
    }
    if (output == null or capacity < out) return -2;
    for (0..out) |i| output[i] = staged[i];
    return @intCast(out);
}
