export fn validate_subsequence(raw_values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 8194) return -1;
    const values = raw_values[0..length];
    if (values[0] < 0 or values[0] > 4096 or values[1] < 0 or values[1] > 4096) return -1;
    const array_length: usize = @intCast(values[0]);
    const sequence_length: usize = @intCast(values[1]);
    if (length != 2 + array_length + sequence_length) return -1;
    for (values[2..]) |value| {
        if (value < -2147483648 or value > 2147483647) return -1;
    }

    if (array_length == 0) return 0;
    if (sequence_length == 0) return 1;
    const sequence_start = 2 + array_length;
    var array_index: usize = 0;
    var sequence_index: usize = 0;
    while (sequence_index < sequence_length and array_index < array_length) : (array_index += 1) {
        if (values[sequence_start + sequence_index] == values[2 + array_index]) sequence_index += 1;
    }
    return if (sequence_index == sequence_length) 1 else 0;
}
