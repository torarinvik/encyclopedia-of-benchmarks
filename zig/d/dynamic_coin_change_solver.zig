pub export fn dynamic_coin_change_solver(input: [*]const i64, length: usize) i64 {
    if (length < 3 or length > 11) return -1;
    const amount = input[0];
    const count = input[1];
    if (amount < 1 or amount > 18 or count < 1 or count > 9 or length != @as(usize, @intCast(count + 2))) return -1;
    var coins: [9]i32 = @splat(0);
    var has_one = false;
    for (0..@as(usize, @intCast(count))) |i| {
        if (input[i + 2] < 1 or input[i + 2] > 9) return -1;
        coins[i] = @intCast(input[i + 2]);
        if (coins[i] == 1) has_one = true;
        for (0..i) |j| if (coins[j] == coins[i]) return -1;
    }
    if (!has_one) return -1;
    for (0..@as(usize, @intCast(count))) |i| {
        for (i + 1..@as(usize, @intCast(count))) |j| if (coins[i] < coins[j]) {
            const temporary = coins[i]; coins[i] = coins[j]; coins[j] = temporary;
        };
    }
    var changes: [19][9]i32 = @splat(@splat(0));
    var sizes: [19]usize = @splat(0);
    for (1..@as(usize, @intCast(amount)) + 1) |value| {
        for (0..@as(usize, @intCast(count))) |i| if (@as(usize, @intCast(coins[i])) <= value) {
            changes[value][sizes[value]] = @as(i32, @intCast(value)) - coins[i];
            sizes[value] += 1;
        };
    }
    var current: usize = @intCast(amount);
    var code: i64 = 0;
    for (0..18) |_| {
        var next: i32 = 2147483647;
        var min_change: i32 = 2147483647;
        for (0..sizes[current]) |i| {
            const change = changes[current][i];
            if (change == 0) { next = 0; break; }
            var minimum: i32 = 2147483647;
            for (0..sizes[@intCast(change)]) |j| minimum = @min(minimum, changes[@intCast(change)][j]);
            if (minimum < min_change) { min_change = minimum; next = change; }
        }
        if (next == 2147483647) return -1;
        code = code * 10 + @as(i64, @intCast(current)) - next;
        if (next == 0) return code;
        current = @intCast(next);
    }
    return -1;
}
