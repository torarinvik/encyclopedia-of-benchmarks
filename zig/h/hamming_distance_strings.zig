/// Count differing byte positions for equal-length input strings.
export fn hamming_distance_strings(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 260) return -1;
    const left_length = input[0];
    const right_length = input[1];
    if (left_length < 0 or left_length > 128 or right_length < 0 or right_length > 128) return -1;
    if (length != @as(usize, @intCast(2 + left_length + right_length))) return -1;
    for (2..length) |index| if (input[index] < 0 or input[index] > 255) return -1;
    if (left_length != right_length) return -1;
    var distance: i64 = 0;
    for (0..@as(usize, @intCast(left_length))) |index| {
        if (input[2 + index] != input[2 + @as(usize, @intCast(left_length)) + index]) distance += 1;
    }
    return distance;
}
