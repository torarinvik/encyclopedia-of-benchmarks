/// Count base-10 digits in the magnitude, including for minInt(i64).
export fn number_of_digits(value: i64) i64 {
    var magnitude: u64 = undefined;
    if (value < 0) magnitude = @as(u64, @intCast(-(value + 1))) + 1
    else magnitude = @intCast(value);
    if (magnitude < 10) return 1;
    var digits: i64 = 1;
    while (magnitude >= 10000) {
        magnitude /= 10000;
        digits += 4;
    }
    if (magnitude < 10) return digits;
    if (magnitude < 100) return digits + 1;
    return digits + @as(i64, if (magnitude < 1000) 2 else 3);
}
