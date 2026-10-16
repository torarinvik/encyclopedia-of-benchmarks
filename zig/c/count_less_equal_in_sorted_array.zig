export fn count_less_equal_in_sorted_array(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 513) return -1;
    const key = input[0];
    if (key < -2_147_483_648 or key > 2_147_483_647) return -1;
    for (1..length) |index| {
        const value = input[index];
        if (value < -2_147_483_648 or value > 2_147_483_647) return -1;
        if (index > 1 and input[index - 1] > value) return -1;
    }

    var left: usize = 1;
    var right: usize = length - 1;
    var count: usize = 0;
    while (left <= right) {
        const middle = left + (right - left) / 2;
        if (input[middle] > key) right = middle - 1 else {
            count = middle;
            left = middle + 1;
        }
    }
    return @intCast(count);
}
