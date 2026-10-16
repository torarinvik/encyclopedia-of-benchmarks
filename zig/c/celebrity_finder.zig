export fn celebrity_finder(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or input[0] < 1 or input[0] > 64) return -2;
    const n: usize = @intCast(input[0]);
    if (length != 1 + n * n) return -2;
    for (1..length) |i| if (input[i] != 0 and input[i] != 1) return -2;
    var stack = [_]usize{0} ** 64;
    var top: usize = 0;
    for (0..n) |i| { stack[top] = i; top += 1; }
    while (top > 1) {
        top -= 1;
        const person1 = stack[top];
        top -= 1;
        const person2 = stack[top];
        stack[top] = if (input[1 + person1 * n + person2] == 1) person2 else person1;
        top += 1;
    }
    const candidate = stack[0];
    for (0..n) |i| {
        if (i != candidate and (input[1 + candidate * n + i] == 1 or input[1 + i * n + candidate] == 0)) return -1;
    }
    return @intCast(candidate);
}
