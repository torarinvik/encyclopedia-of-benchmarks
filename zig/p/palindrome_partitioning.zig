const MAX_LENGTH: usize = 256;

export fn palindrome_partitioning(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > MAX_LENGTH) return -1;
    for (0..length) |index| {
        if (input[index] < 0 or input[index] > 127) return -1;
    }
    if (output_capacity < 8) return -2;

    var palindrome = [_][MAX_LENGTH]bool{[_]bool{false} ** MAX_LENGTH} ** MAX_LENGTH;
    var cuts = [_]i64{0} ** MAX_LENGTH;
    for (0..length) |end| {
        var best: i64 = @intCast(end);
        for (0..end + 1) |start| {
            if (input[start] == input[end] and
                (end - start < 2 or palindrome[start + 1][end - 1])) {
                palindrome[start][end] = true;
                const candidate: i64 = if (start == 0) 0 else cuts[start - 1] + 1;
                if (candidate < best) best = candidate;
            }
        }
        cuts[end] = best;
    }

    const bits: u64 = @intCast(cuts[length - 1]);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
    return 1;
}
