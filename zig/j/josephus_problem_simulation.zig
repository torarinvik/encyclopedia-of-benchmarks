export fn josephus_problem_simulation(values: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const n = values[0];
    const step = values[1];
    if (n < 1 or n > 512 or step < 1) return -1;
    var people: [512]i64 = undefined;
    var remaining: usize = @intCast(n);
    for (0..remaining) |i| people[i] = @as(i64, @intCast(i)) + 1;
    var current: usize = 0;
    while (remaining > 1) {
        const offset: usize = @intCast(@mod(step - 1, @as(i64, @intCast(remaining))));
        const removed = (current + offset) % remaining;
        for (removed..remaining - 1) |i| people[i] = people[i + 1];
        remaining -= 1;
        current = removed % remaining;
    }
    return people[0];
}
