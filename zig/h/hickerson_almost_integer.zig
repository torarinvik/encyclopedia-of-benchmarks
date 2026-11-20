const INVALID_RESULT: f64 = -1.0e300;

export fn hickerson_almost_integer(values: ?[*]const i64, length: usize) f64 {
    if (values == null or length != 1) return INVALID_RESULT;
    const n = values.?[0];
    if (n < 1 or n > 17) return INVALID_RESULT;
    const log_two = @log(2.0);
    var value = 1.0 / (2.0 * log_two * log_two);
    var index: i64 = 2;
    while (index <= n) : (index += 1) value = (@as(f64, @floatFromInt(index)) / log_two) * value;
    return value;
}
