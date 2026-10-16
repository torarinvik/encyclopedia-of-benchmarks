export fn select_bits(values: ?[*]const i64, length: usize) i64 {
    const input = values orelse return -1;
    if (length < 1 or length > 3) return -1;

    const number = input[0];
    if (number < 0 or number > 9007199254740991) return -1;

    const first: i64 = if (length >= 2) input[1] else 1;
    const last: i64 = if (length >= 3) input[2] else 53;
    if (first < 1 or first > 53 or last < 1 or last > 53) return -1;

    const modulus: i64 = @as(i64, 1) << @intCast(last);
    return (number % modulus) >> @intCast(first - 1);
}
