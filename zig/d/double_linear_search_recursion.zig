const MAX_ITEMS: i64 = 1024;
const INVALID_RESULT: i64 = -2;

fn searchRange(values: [*]const i64, key: i64, left: i64, right: i64, offset: usize) i64 {
    if (left > right) return -1;
    if (values[offset + @as(usize, @intCast(left))] == key) return left;
    if (values[offset + @as(usize, @intCast(right))] == key) return right;
    return searchRange(values, key, left + 1, right - 1, offset);
}

pub export fn double_linear_search_recursion(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > @as(usize, @intCast(MAX_ITEMS + 2))) return INVALID_RESULT;
    const count = input[0];
    const key = input[1];
    if (count < 0 or count > MAX_ITEMS or key < -2147483648 or key > 2147483647 or
        length != @as(usize, @intCast(2 + count))) return INVALID_RESULT;
    for (0..@as(usize, @intCast(count))) |index| {
        const value = input[2 + index];
        if (value < -2147483648 or value > 2147483647) return INVALID_RESULT;
    }
    return searchRange(input, key, 0, count - 1, 2);
}
