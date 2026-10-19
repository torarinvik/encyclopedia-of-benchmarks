const MAX_LENGTH: usize = 4096;

export fn ary3(length: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > 4096) return -1;
    const n: usize = @intCast(length);
    var x: [MAX_LENGTH]i32 = @splat(0);
    var y: [MAX_LENGTH]i32 = @splat(0);
    for (0..n) |index| {
        x[index] = @intCast(index + 1);
        y[index] = 0;
    }
    for (0..1000) |_| {
        var index = n;
        while (index > 0) {
            index -= 1;
            y[index] += x[index];
        }
    }

    var first: u32 = @intCast(y[0]);
    var last: u32 = @intCast(y[n - 1]);
    var first_reversed: [10]u8 = @splat(0);
    var first_digit_count: usize = 0;
    while (first > 0) {
        first_reversed[first_digit_count] = @intCast(48 + first % 10);
        first_digit_count += 1;
        first /= 10;
    }
    var reversed: [10]u8 = @splat(0);
    var digit_count: usize = 0;
    while (last > 0) {
        reversed[digit_count] = @intCast(48 + last % 10);
        digit_count += 1;
        last /= 10;
    }
    const required = first_digit_count + 2 + digit_count;
    if (output_opt == null or output_capacity < required) return -2;
    const output = output_opt.?;
    for (0..first_digit_count) |index| output[index] = first_reversed[first_digit_count - index - 1];
    output[first_digit_count] = ' ';
    for (0..digit_count) |index| output[first_digit_count + 1 + index] = reversed[digit_count - index - 1];
    output[required - 1] = '\n';
    return @intCast(required);
}
