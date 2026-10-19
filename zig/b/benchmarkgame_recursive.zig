const MAX_N: i64 = 10;
const MAX_OUTPUT_BYTES: usize = 89;

fn ackermannValue(x: i64, y: i64) i64 {
    if (x == 0) return y + 1;
    return ackermannValue(x - 1, if (y == 0) 1 else ackermannValue(x, y - 1));
}

fn fibonacciInteger(n: i64) i64 {
    if (n < 2) return 1;
    return fibonacciInteger(n - 2) + fibonacciInteger(n - 1);
}

fn fibonacciFloat(n: f64) f64 {
    if (n < 2.0) return 1.0;
    return fibonacciFloat(n - 2.0) + fibonacciFloat(n - 1.0);
}

fn takeuchiInteger(x: i64, y: i64, z: i64) i64 {
    if (y < x) return takeuchiInteger(takeuchiInteger(x - 1, y, z),
        takeuchiInteger(y - 1, z, x), takeuchiInteger(z - 1, x, y));
    return z;
}

fn takeuchiFloat(x: f64, y: f64, z: f64) f64 {
    if (y < x) return takeuchiFloat(takeuchiFloat(x - 1.0, y, z),
        takeuchiFloat(y - 1.0, z, x), takeuchiFloat(z - 1.0, x, y));
    return z;
}

fn appendText(buffer: *[MAX_OUTPUT_BYTES]u8, used: *usize, text: []const u8) void {
    for (text) |byte| {
        buffer[used.*] = byte;
        used.* += 1;
    }
}

fn appendNumber(buffer: *[MAX_OUTPUT_BYTES]u8, used: *usize, value: i64) void {
    var reversed: [20]u8 = undefined;
    var remaining = value;
    var count: usize = 0;
    while (true) {
        reversed[count] = @intCast(48 + @mod(remaining, 10));
        count += 1;
        remaining = @divTrunc(remaining, 10);
        if (remaining == 0) break;
    }
    while (count > 0) {
        count -= 1;
        buffer[used.*] = reversed[count];
        used.* += 1;
    }
}

export fn benchmarkgame_recursive(n: i64, output_opt: ?[*]u8,
    output_capacity: usize) i64 {
    if (n < 0 or n > MAX_N) return -1;
    if (output_opt == null) return -2;

    var staged: [MAX_OUTPUT_BYTES]u8 = undefined;
    var used: usize = 0;
    appendText(&staged, &used, "Ack(3,");
    appendNumber(&staged, &used, n + 1);
    appendText(&staged, &used, "): ");
    appendNumber(&staged, &used, ackermannValue(3, n + 1));
    appendText(&staged, &used, "\nFib(");
    appendNumber(&staged, &used, 28 + n);
    appendText(&staged, &used, ".0): ");
    appendNumber(&staged, &used, @intFromFloat(fibonacciFloat(@floatFromInt(28 + n))));
    appendText(&staged, &used, ".0\nTak(");
    appendNumber(&staged, &used, 3 * n);
    appendText(&staged, &used, ",");
    appendNumber(&staged, &used, 2 * n);
    appendText(&staged, &used, ",");
    appendNumber(&staged, &used, n);
    appendText(&staged, &used, "): ");
    appendNumber(&staged, &used, takeuchiInteger(3 * n, 2 * n, n));
    appendText(&staged, &used, "\nFib(3): ");
    appendNumber(&staged, &used, fibonacciInteger(3));
    appendText(&staged, &used, "\nTak(3.0,2.0,1.0): ");
    appendNumber(&staged, &used, @intFromFloat(takeuchiFloat(3.0, 2.0, 1.0)));
    appendText(&staged, &used, ".0\n");

    if (output_capacity < used) return -2;
    const output = output_opt.?;
    for (0..used) |index| output[index] = staged[index];
    return @intCast(used);
}
