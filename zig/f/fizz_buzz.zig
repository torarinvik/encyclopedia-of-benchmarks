fn tokenLength(value: i64) usize {
    if (@mod(value, 15) == 0) return 8;
    if (@mod(value, 3) == 0 or @mod(value, 5) == 0) return 4;
    if (value >= 100) return 3;
    if (value >= 10) return 2;
    return 1;
}

fn appendNumber(valueValue: i64, output: [*]u8, positionValue: usize) usize {
    var value = valueValue;
    var position = positionValue;
    if (value >= 100) {
        output[position] = @intCast(48 + @divTrunc(value, 100));
        position += 1;
        value = @mod(value, 100);
        output[position] = @intCast(48 + @divTrunc(value, 10));
        position += 1;
        output[position] = @intCast(48 + @mod(value, 10));
        position += 1;
    } else if (value >= 10) {
        output[position] = @intCast(48 + @divTrunc(value, 10));
        position += 1;
        output[position] = @intCast(48 + @mod(value, 10));
        position += 1;
    } else {
        output[position] = @intCast(48 + value);
        position += 1;
    }
    return position;
}

export fn fizz_buzz(value: i64, output: [*]u8, output_capacity: usize) i64 {
    if (value < 1 or value > 512) return -1;
    var width: usize = 0;
    var current: i64 = 1;
    while (current <= value) : (current += 1) width += tokenLength(current) + 1;
    if (output_capacity < width) return -2;
    var position: usize = 0;
    current = 1;
    while (current <= value) : (current += 1) {
        if (@mod(current, 15) == 0) {
            @memcpy(output[position .. position + 8], "FizzBuzz");
            position += 8;
        } else if (@mod(current, 3) == 0) {
            @memcpy(output[position .. position + 4], "Fizz");
            position += 4;
        } else if (@mod(current, 5) == 0) {
            @memcpy(output[position .. position + 4], "Buzz");
            position += 4;
        } else {
            position = appendNumber(current, output, position);
        }
        output[position] = ' ';
        position += 1;
    }
    return @intCast(position);
}
