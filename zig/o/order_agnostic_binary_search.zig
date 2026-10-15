/// Binary search over a monotone sequence in either direction.
export fn order_agnostic_binary_search(values: [*]const i64, length: usize) i64 {
    if (length < 3 or length > 100_001) return -1;
    const input = values[0..length];
    const target = input[0];
    const count_value = input[1];
    if (target < -2_147_483_648 or target > 2_147_483_647 or count_value < 1 or count_value > 99_999 or
        length != @as(usize, @intCast(count_value)) + 2) return -1;
    const count: usize = @intCast(count_value);
    const ascending = input[2] < input[count + 1];
    var start: i64 = 0;
    var right: i64 = count_value - 1;
    while (start <= right) {
        const middle = start + @divTrunc(right - start, 2);
        const value = input[@as(usize, @intCast(middle)) + 2];
        if (value == target) return middle;
        if (ascending) {
            if (value < target) start = middle + 1 else right = middle - 1;
        } else {
            if (value > target) start = middle + 1 else right = middle - 1;
        }
    }
    return -1;
}
