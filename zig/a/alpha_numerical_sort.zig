/// Compare lowercase ASCII alphanumeric strings in natural order.
fn isDigit(value: i64) bool { return value >= 48 and value <= 57; }
fn validString(values: []const i64) bool {
    for (values, 0..) |value, i| {
        if (!isDigit(value) and (value < 97 or value > 122)) return false;
        if (value == 48 and i > 0 and isDigit(values[i - 1])) return false;
    }
    return true;
}
export fn alpha_numerical_sort(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2) return -2;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 64) return -2;
    const first_length: usize = @intCast(values[0]);
    if (1 + first_length >= length or values[1 + first_length] < 0 or values[1 + first_length] > 64) return -2;
    const second_length: usize = @intCast(values[1 + first_length]);
    if (length != 2 + first_length + second_length) return -2;
    const first = values[2 .. 2 + first_length];
    const second = values[2 + first_length .. length];
    if (!validString(first) or !validString(second)) return -2;
    var i: usize = 0;
    var j: usize = 0;
    while (i < first_length and j < second_length) {
        const a, const b = .{ first[i], second[j] };
        if (isDigit(a) and isDigit(b)) {
            var end_a = i;
            var end_b = j;
            while (end_a < first_length and isDigit(first[end_a])) : (end_a += 1) {}
            while (end_b < second_length and isDigit(second[end_b])) : (end_b += 1) {}
            const digits_a = end_a - i;
            const digits_b = end_b - j;
            if (digits_a != digits_b) return if (digits_a < digits_b) -1 else 1;
            for (0..digits_a) |k| if (first[i + k] != second[j + k]) return if (first[i + k] < second[j + k]) -1 else 1;
            i = end_a;
            j = end_b;
        } else {
            if (a != b) return if (a < b) -1 else 1;
            i += 1;
            j += 1;
        }
    }
    if (i == first_length and j == second_length) return 0;
    return if (i == first_length) -1 else 1;
}
