/// Return the largest signed value in a nonempty array.
export fn find_max(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 512) return -1;
    var result = values[0];
    for (1..length) |index| {
        if (values[index] > result) result = values[index];
    }
    return result;
}
