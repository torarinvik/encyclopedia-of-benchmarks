/// Bounded half-open worker search returning its found flag.
export fn linear_search_thread(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > 69) return -1;
    const count_arg = input[0];
    const left = input[1];
    const right = input[2];
    const target = input[3];
    if (count_arg < 1 or count_arg > 64 or length != @as(usize, @intCast(count_arg)) + 4) return -1;
    if (left < 0 or left > right or right > count_arg or
        target < -2147483648 or target > 2147483647) return -1;
    const count: usize = @intCast(count_arg);
    for (0..count) |index| {
        const value = input[index + 4];
        if (value < -2147483648 or value > 2147483647) return -1;
    }
    for (@as(usize, @intCast(left))..@as(usize, @intCast(right))) |index| {
        if (input[index + 4] == target) return 1;
    }
    return 0;
}
