export fn softmax(values: [*c]const f64, length: usize,
                  output: [*c]f64, capacity: usize) i64 {
    if (values == null or length == 0 or length > 64) return -1;
    for (0..length) |index| {
        const value = values[index];
        if (value != value or value < -20.0 or value > 20.0) return -1;
    }
    if (output == null or capacity < length) return -2;

    var total: f64 = 0.0;
    for (0..length) |index| total += @exp(values[index]);
    for (0..length) |index| output[index] = @exp(values[index]) / total;
    return @intCast(length);
}
