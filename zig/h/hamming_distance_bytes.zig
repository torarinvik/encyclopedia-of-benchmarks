const max_byte_length: i64 = 1024;

/// Count differing byte positions in two equal-length byte strings.
export fn hamming_distance_bytes(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > 2050) return -1;
    const count_value = values[0];
    if (count_value < 0 or count_value > max_byte_length or
        length != 1 + 2 * @as(usize, @intCast(count_value))) return -1;

    const count: usize = @intCast(count_value);
    var distance: i64 = 0;
    for (0..count) |index| {
        const left = values[index + 1];
        const right = values[count + index + 1];
        if (left < 0 or left > 255 or right < 0 or right > 255) return -1;
        if (left != right) distance += 1;
    }
    return distance;
}
