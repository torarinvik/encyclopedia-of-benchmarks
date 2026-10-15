const MAX_ABS_VALUE: i64 = 1_000_000;

export fn finding_number_of_digits_in_a_number_using_log(value: i64) i64 {
    if (value < -MAX_ABS_VALUE or value > MAX_ABS_VALUE) return -1;
    if (value == 0) return 0;
    const magnitude: f64 = @floatFromInt(if (value < 0) -value else value);
    return @intFromFloat(@floor(@log10(magnitude) + 1.0));
}
