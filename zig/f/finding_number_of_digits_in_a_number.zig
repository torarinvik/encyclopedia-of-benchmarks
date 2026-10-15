export fn finding_number_of_digits_in_a_number(value: i64) i64 {
    if (value < 0) return -1;
    var remaining: u64 = @intCast(value);
    var count: i64 = 0;
    while (remaining != 0) {
        remaining /= 10;
        count += 1;
    }
    return count;
}
