/// Count base-10 digits in the magnitude, including for minInt(i64).
export fn number_of_digits(value: i64) i64 {
    var magnitude: u64 = undefined;
    if (value < 0) magnitude = @as(u64, @intCast(-(value + 1))) + 1
    else magnitude = @intCast(value);
    var digits: i64 = 1;
    while (magnitude >= 10) {
        magnitude /= 10;
        digits += 1;
    }
    return digits;
}
