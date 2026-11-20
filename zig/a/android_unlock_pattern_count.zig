fn middlePoint(first: usize, second: usize) ?usize {
    if (first == second) return null;
    const first_x: isize = @intCast(first % 3);
    const first_y: isize = @intCast(first / 3);
    const second_x: isize = @intCast(second % 3);
    const second_y: isize = @intCast(second / 3);
    const delta_x = second_x - first_x;
    const delta_y = second_y - first_y;
    if (@mod(delta_x, 2) != 0 or @mod(delta_y, 2) != 0) return null;
    const middle_x = @divTrunc(first_x + second_x, 2);
    const middle_y = @divTrunc(first_y + second_y, 2);
    const middle: usize = @intCast(middle_y * 3 + middle_x);
    if (middle == first or middle == second) return null;
    return middle;
}

fn countFrom(last: usize, visited: usize, used: usize, target: usize) i64 {
    if (used == target) return 1;
    var count: i64 = 0;
    for (0..9) |next| {
        const bit = @as(usize, 1) << next;
        if (visited & bit != 0) continue;
        if (middlePoint(last, next)) |middle| {
            if (visited & (@as(usize, 1) << middle) == 0) continue;
        }
        count += countFrom(next, visited | bit, used + 1, target);
    }
    return count;
}

fn solve(input: []const i64) i64 {
    if (input.len != 1 or input[0] < 4 or input[0] > 9) return -1;
    const target: usize = @intCast(input[0]);
    var count: i64 = 0;
    for (0..9) |start| {
        count += countFrom(start, @as(usize, 1) << start, 1, target);
    }
    return count;
}

pub export fn android_unlock_pattern_count(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 1) return -1;
    return solve(input[0..length]);
}
