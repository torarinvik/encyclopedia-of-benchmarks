export fn keith_number(number: i64) i64 {
    if (number < 10 or number > 999999) return -1;

    var reversed: [6]i64 = .{0, 0, 0, 0, 0, 0};
    var digits: [6]i64 = .{0, 0, 0, 0, 0, 0};
    var value = number;
    var digit_count: usize = 0;
    while (value > 0) {
        reversed[digit_count] = @mod(value, 10);
        digit_count += 1;
        value = @divTrunc(value, 10);
    }
    for (0..digit_count) |i| {
        digits[i] = reversed[digit_count - 1 - i];
    }

    var oldest: usize = 0;
    while (true) {
        var next: i64 = 0;
        for (0..digit_count) |i| {
            next += digits[(oldest + i) % digit_count];
        }
        if (next >= number) return if (next == number) 1 else 0;
        digits[oldest] = next;
        oldest = (oldest + 1) % digit_count;
    }
}
