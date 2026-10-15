/// Copy positive list values, then scan each mirrored twin pair.
const MAX_LENGTH: usize = 1024;

export fn maximum_twin_sum_of_linked_list(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_LENGTH or length % 2 != 0) return -1;
    var copied: [MAX_LENGTH]i32 = undefined;
    for (0..length) |index| {
        if (values[index] < 1 or values[index] > 100000) return -1;
        copied[index] = @intCast(values[index]);
    }
    var maximum: i64 = 0;
    for (0..length / 2) |index| {
        const twin_sum = @as(i64, copied[index]) + copied[length - index - 1];
        if (twin_sum > maximum) maximum = twin_sum;
    }
    return maximum;
}
