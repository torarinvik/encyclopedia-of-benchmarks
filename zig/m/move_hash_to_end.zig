export fn move_hash_to_end(values: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 1 or length > 258) return -1;
    const text_length = values[0];
    if (text_length < 0 or text_length > 256 or length != @as(usize, @intCast(text_length)) + 1) return -1;
    const n: usize = @intCast(text_length);
    for (0..n) |i| if (values[i + 1] < 0 or values[i + 1] > 127) return -1;
    if (capacity < n or (n > 0 and output == null)) return -2;
    if (n == 0) return 0;
    var position: usize = 0;
    for (0..n) |i| {
        if (values[i + 1] != 35) { output[position] = @intCast(values[i + 1]); position += 1; }
    }
    while (position < n) : (position += 1) output[position] = '#';
    return @intCast(n);
}
