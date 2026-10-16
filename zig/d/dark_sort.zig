/// Dark sort: counting sort for nonnegative keys in [0, 128].
export fn dark_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    const input = values[0..length];
    var maximum = input[0];
    for (input[1..]) |value| if (value > maximum) { maximum = value; };
    var counts = [_]i64{0} ** 129;
    for (input) |value| counts[@intCast(value)] += 1;
    var output: usize = 0;
    var value: i64 = 0;
    while (value <= maximum) : (value += 1) {
        while (counts[@intCast(value)] > 0) {
            input[output] = value;
            output += 1;
            counts[@intCast(value)] -= 1;
        }
    }
}
