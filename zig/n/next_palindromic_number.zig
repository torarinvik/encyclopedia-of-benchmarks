const MAX_INPUT: i64 = 9_999_999_999_999_999;

fn nextFor(number: i64) i64 {
    var digits: [17]u8 = @splat(0);
    var remaining = number;
    var count: usize = 0;
    while (true) {
        digits[count] = @intCast(@mod(remaining, 10));
        count += 1;
        remaining = @divTrunc(remaining, 10);
        if (remaining == 0) break;
    }
    for (0..count / 2) |left| {
        const right = count - 1 - left;
        const swap = digits[left];
        digits[left] = digits[right];
        digits[right] = swap;
    }
    for (0..count / 2) |left| digits[count - 1 - left] = digits[left];
    var candidate: i64 = 0;
    for (0..count) |i| candidate = candidate * 10 + @as(i64, digits[i]);
    if (candidate > number) return candidate;

    var position = (count + 1) / 2;
    while (position > 0 and digits[position - 1] == 9) {
        digits[position - 1] = 0;
        position -= 1;
    }
    if (position == 0) {
        var power: i64 = 1;
        for (0..count) |_| power *= 10;
        return power + 1;
    }
    digits[position - 1] += 1;
    for (0..count / 2) |left| digits[count - 1 - left] = digits[left];
    candidate = 0;
    for (0..count) |i| candidate = candidate * 10 + @as(i64, digits[i]);
    return candidate;
}

export fn next_palindromic_number(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length != 1) return -1;
    const number = values.?[0];
    if (number < 0 or number > MAX_INPUT) return -1;
    return nextFor(number);
}
