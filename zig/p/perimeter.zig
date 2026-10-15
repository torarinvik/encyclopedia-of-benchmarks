export fn perimeter(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length != 2) return -1;
    const input = values.?[0..length];
    const sides = input[0];
    const side_length = input[1];
    if (sides < 3 or sides > 256 or side_length < 1 or side_length > 255) return -1;
    return sides * side_length;
}
