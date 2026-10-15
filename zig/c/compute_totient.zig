fn decimalLength(valueInput: i64) usize {
    var value = valueInput;
    var length: usize = 1;
    while (value >= 10) : (length += 1) { value = @divTrunc(value, 10); }
    return length;
}

fn appendDecimal(valueInput: i64, output: [*]u8, positionInput: usize) usize {
    var digits: [3]u8 = undefined;
    var count: usize = 0;
    var value = valueInput;
    while (true) {
        digits[count] = @intCast(@rem(value, 10));
        count += 1;
        value = @divTrunc(value, 10);
        if (value == 0) break;
    }
    var position = positionInput;
    while (count > 0) {
        count -= 1;
        output[position] = '0' + digits[count];
        position += 1;
    }
    return position;
}

export fn compute_totient(n: i64, output: [*]u8, output_capacity: usize) i64 {
    if (n < 1 or n > 80) return -1;
    var phi: [80]i64 = undefined;
    for (1..@intCast(n + 1)) |i| phi[i - 1] = @intCast(i);
    for (2..@intCast(n + 1)) |p| {
        if (phi[p - 1] != @as(i64, @intCast(p))) continue;
        phi[p - 1] = @as(i64, @intCast(p)) - 1;
        var i = 2 * p;
        while (i <= n) : (i += p) {
            phi[i - 1] = @divTrunc(phi[i - 1], @intCast(p)) * (@as(i64, @intCast(p)) - 1);
        }
    }
    var required: usize = @intCast(n - 1);
    for (0..@intCast(n)) |i| required += decimalLength(phi[i]);
    if (output_capacity < required) return -2;
    var position: usize = 0;
    for (0..@intCast(n)) |i| {
        if (i > 0) { output[position] = ','; position += 1; }
        position = appendDecimal(phi[i], output, position);
    }
    return @intCast(position);
}
