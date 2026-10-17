export fn logistic_regression_predict(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > 2051) return -1;
    const rows = values[0]; const features = values[1];
    if (rows < 1 or rows > 63 or features < 1 or features > 32) return -1;
    const rows_usize: usize = @intCast(rows); const features_usize: usize = @intCast(features);
    if (length != 2 + rows_usize * features_usize + features_usize) return -1;
    const theta_offset = 2 + rows_usize * features_usize;
    for (0..rows_usize * features_usize + features_usize) |i| { if (values[2 + i] < -1000 or values[2 + i] > 1000) return -1; }
    var mask: u64 = 0;
    for (0..rows_usize) |row| {
        var score: i64 = 0;
        for (0..features_usize) |feature| score += values[2 + row * features_usize + feature] * values[theta_offset + feature];
        if (score >= 0) mask |= @as(u64, 1) << @intCast(row);
    }
    return @intCast(mask);
}
