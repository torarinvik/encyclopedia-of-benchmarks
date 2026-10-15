export fn search_insert_position(input: [*]const i64, length: usize) i64 {
    if (length < 1 or length > 257) return -1;
    const target = input[0];
    if (target < -2_147_483_648 or target > 2_147_483_647) return -1;
    for (1..length) |index| {
        const value = input[index];
        if (value < -2_147_483_648 or value > 2_147_483_647) return -1;
        if (index > 1 and input[index - 1] >= value) return -1;
    }
    var low: usize = 0;
    var high: usize = length - 1;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (input[middle + 1] < target) low = middle + 1 else high = middle;
    }
    return @intCast(low);
}
