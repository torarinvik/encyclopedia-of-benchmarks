const MAX_LENGTH: usize = 4096;

/// Count transitions from ASCII space to a non-space byte.
export fn count_segments(input: [*c]const i64, length: usize) i64 {
    if (length > MAX_LENGTH or (length != 0 and input == null)) return -1;
    var count: i64 = 0;
    var previous_was_space = true;
    for (0..length) |index| {
        const value = input[index];
        if (value < 1 or value > 127) return -1;
        if (value != 32 and previous_was_space) count += 1;
        previous_was_space = value == 32;
    }
    return count;
}
