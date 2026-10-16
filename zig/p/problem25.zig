export fn problem25(requested_digits: i64) i64 {
    if (requested_digits < 2 or requested_digits > 1000) return -1;
    var previous = [_]u8{0} ** 1000;
    var current = [_]u8{0} ** 1000;
    var next = [_]u8{0} ** 1000;
    previous[0] = 1;
    current[0] = 1;
    var active_digits: usize = 1;
    var index: i64 = 2;
    while (active_digits < @as(usize, @intCast(requested_digits))) {
        var carry: u8 = 0;
        for (0..active_digits) |position| {
            const total = @as(u16, previous[position]) + @as(u16, current[position]) + carry;
            next[position] = @intCast(total % 10);
            carry = @intCast(total / 10);
        }
        if (carry != 0) {
            next[active_digits] = carry;
            active_digits += 1;
        }
        for (0..active_digits) |position| {
            previous[position] = current[position];
            current[position] = next[position];
        }
        index += 1;
    }
    return index;
}
